CREATE OR REPLACE PROCEDURE HACKATHON_SNOWFLAKE.TRANSPORTATION.SP_VEHICLE_TELEMETRY(P_START_DATE DATE)
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
    FROM HACKATHON_SNOWFLAKE.TRANSPORTATION.VEHICLE_TELEMETRY_COMPLETE;

    -- Hitung jumlah file di internal stage folder 'vehicle_telemetry/'
    SELECT COUNT(*) 
    INTO v_file_count
    FROM DIRECTORY(@TRANSPORTATION_INT_STAGE)
    WHERE relative_path LIKE 'vehicle_telemetry/year=' || :v_year || '/month=' || :v_month || '/%'
       OR STARTSWITH(relative_path, 'vehicle_telemetry/year=' || :v_year || '/month=' || :v_month || '/');

        -- Jika ada file dan data masih kosong, CALL SP Ingestion
    IF (v_file_count > 0 AND v_data_count = 0) THEN
    
        CALL HACKATHON_SNOWFLAKE.TRANSPORTATION.SP_ING_RENTALS_VEHICLE('vehicle_telemetry');

        RETURN '✅ Data loaded successfully from all paths';
        
    ELSEIF (v_data_count > 0 AND v_data_count > 0) THEN
    
        -- Hapus data pada tabel untuk periode tersebut
        v_sql := 'DELETE FROM HACKATHON_SNOWFLAKE.TRANSPORTATION.VEHICLE_TELEMETRY_COMPLETE
                  WHERE PERIOD = ' || v_period;
        EXECUTE IMMEDIATE v_sql;
    
        -- Copy file CSV dari stage ke tabel
        v_sql := 'COPY INTO HACKATHON_SNOWFLAKE.TRANSPORTATION.VEHICLE_TELEMETRY_COMPLETE
                  FROM (
                    SELECT 
                        TO_CHAR(TRY_TO_TIMESTAMP($2), ''YYYYMM'') AS PERIOD,
                        $1,
                        $2::TIMESTAMP_NTZ AS TIMESTAMP,
                        $3::FLOAT,
                        $4::FLOAT,
                        $5::FLOAT,
                        $6::FLOAT,
                        $7::FLOAT,
                        $8::FLOAT,
                        $9::FLOAT,
                        $10,
                        $11,
                        $12
                    FROM @transportation_int_stage/vehicle_telemetry/year=' || v_year || '/month=' || v_month || '/
                  )
                  FILE_FORMAT = (TYPE = ''CSV'' FIELD_DELIMITER = '','' SKIP_HEADER = 1)
                  PATTERN = ''.*\\.csv''
                    FORCE=TRUE
                  ON_ERROR = ''SKIP_FILE''';
        EXECUTE IMMEDIATE v_sql;
    
        -- Insert log eksekusi
        INSERT INTO HACKATHON_SNOWFLAKE.TRANSPORTATION.TABLE_LOG
        VALUES ('SP_VEHICLE_TELEMETRY', :v_curr_timestamp, 'SUCCESS', 'File(s) found in @TRANSPORTATION_INT_STAGE/vehicle_telemetry/year=' || :v_year || '/month=' || :v_month || ' — Load data successfully');
    
        RETURN '✅ Success: ' || :v_file_count || ' file(s) found and loaded.';

    ELSE
        -- Jika tidak ada file
        INSERT INTO HACKATHON_SNOWFLAKE.TRANSPORTATION.TABLE_LOG
        VALUES ('SP_VEHICLE_TELEMETRY', :v_curr_timestamp, 'SKIPPED', 'No files found in @TRANSPORTATION_INT_STAGE/vehicle_telemetry/year=' || :v_year || '/month=' || :v_month);

        RETURN '⚠️ No files found in @TRANSPORTATION_INT_STAGE/vehicle_telemetry/year=' || :v_year || '/month=' || :v_month || '. Process skipped.';
    END IF;
END;
$$;