CREATE OR REPLACE PROCEDURE SP_RENTALS(P_START_DATE DATE)
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    v_year      INT;
    v_month     INT;
    v_period    STRING;
    v_sql       STRING;
    v_curr_timestamp TIMESTAMP;
    v_file_count NUMBER;
    v_data_count NUMBER;
BEGIN
    -- Ambil nilai tahun, bulan, dan periode (YYYYMM)
    v_year   := YEAR(P_START_DATE);
    v_month  := MONTH(P_START_DATE);
    v_period := TO_CHAR(P_START_DATE, 'YYYYMM');
    v_curr_timestamp := CONVERT_TIMEZONE('Asia/Jakarta', CURRENT_TIMESTAMP());

    -- Cek data
    SELECT COUNT(1)
    INTO v_data_count
    FROM HACKATHON_SNOWFLAKE.TRANSPORTATION.RENTALS;
    
    -- Hitung jumlah file di internal stage folder 'rentals/'
    SELECT COUNT(*) 
    INTO v_file_count
    FROM DIRECTORY(@TRANSPORTATION_INT_STAGE)
    WHERE relative_path LIKE 'rentals/year=' || :v_year || '/month=' || :v_month || '/%'
       OR STARTSWITH(relative_path, 'rentals/year=' || :v_year || '/month=' || :v_month || '/');

       -- Jika ada file dan data masih kosong, CALL SP Ingestion
    IF (v_data_count = 0) THEN
    
        CALL HACKATHON_SNOWFLAKE.TRANSPORTATION.SP_ING_RENTALS_VEHICLE('rentals');

        RETURN '✅ Data loaded successfully from all paths';
        
    ELSEIF (v_file_count > 0 AND v_data_count > 0) THEN
        
        -- Hapus data pada tabel untuk periode tersebut
        v_sql := 'DELETE FROM HACKATHON_SNOWFLAKE.TRANSPORTATION.RENTALS
                    WHERE PERIOD = ' || v_period;
        EXECUTE IMMEDIATE v_sql;
    
        -- Copy file CSV dari stage ke tabel
        v_sql := 'COPY INTO HACKATHON_SNOWFLAKE.TRANSPORTATION.RENTALS
              FROM (
                SELECT 
                    TO_CHAR(TRY_TO_TIMESTAMP($4), ''YYYYMM'') AS PERIOD,
                    $1,
                    $2,
                    $3,
                    $4::DATE AS RENTAL_DATE,
                    $5::DATE AS RETURN_DATE,
                    $6::DATE AS ACTUAL_RETURN,
                    $7,
                    $8,
                    $9,
                    $10,
                    $11
                FROM @transportation_int_stage/rentals/year=' || v_year || '/month=' || v_month || '/
              )
              FILE_FORMAT = (TYPE = ''CSV'' FIELD_DELIMITER = '','' SKIP_HEADER = 1)
              PATTERN = ''.*\\.csv''
                FORCE=TRUE
              ON_ERROR = ''SKIP_FILE''';
        EXECUTE IMMEDIATE v_sql;
    
        -- Insert log eksekusi
        INSERT INTO HACKATHON_SNOWFLAKE.TRANSPORTATION.TABLE_LOG
        VALUES ('SP_RENTALS', :v_curr_timestamp, 'SUCCESS', 'File(s) found in @TRANSPORTATION_INT_STAGE/rentals/year=' || :v_year || '/month=' || :v_month || ' — Load data successfully');
    
        RETURN '✅ Success: ' || :v_file_count || ' file(s) found and loaded.';

    ELSE
        -- Jika tidak ada file
        INSERT INTO HACKATHON_SNOWFLAKE.TRANSPORTATION.TABLE_LOG
        VALUES ('SP_RENTALS', :v_curr_timestamp, 'SKIPPED', 'No files found in @TRANSPORTATION_INT_STAGE/rentals/year=' || :v_year || '/month=' || :v_month);

        RETURN '⚠️ No files found in @TRANSPORTATION_INT_STAGE/rentals/year=' || :v_year || '/month=' || :v_month || '. Process skipped.';
    END IF;
END;
$$;