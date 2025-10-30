CREATE OR REPLACE PROCEDURE HACKATHON_SNOWFLAKE.TRANSPORTATION.SP_MAINTENANCES()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    v_curr_timestamp TIMESTAMP;
    v_file_count NUMBER;
BEGIN
    v_curr_timestamp := CONVERT_TIMEZONE('Asia/Jakarta', CURRENT_TIMESTAMP());
    
    -- Hitung jumlah file di internal stage folder 'maintenances/'
    SELECT COUNT(*) 
    INTO v_file_count
    FROM DIRECTORY(@TRANSPORTATION_INT_STAGE)
    WHERE relative_path LIKE 'maintenances/%'
    OR STARTSWITH(relative_path, 'maintenances/');

    -- Jika ada file, lanjutkan proses
    IF (v_file_count > 0) THEN
        
        -- Hapus data lama
        TRUNCATE TABLE HACKATHON_SNOWFLAKE.TRANSPORTATION.MAINTENANCES;
    
        -- Copy file CSV ke tabel utama
        COPY INTO HACKATHON_SNOWFLAKE.TRANSPORTATION.MAINTENANCES
        FROM @TRANSPORTATION_INT_STAGE/maintenances/
        FILE_FORMAT = (
            TYPE = CSV
            FIELD_DELIMITER = ','
            FIELD_OPTIONALLY_ENCLOSED_BY = '"'
            SKIP_HEADER = 1
            NULL_IF = ('NULL', 'null', '')
        )
        PATTERN = '.*\\.csv'
        FORCE=TRUE
        ;
    
        -- Insert log eksekusi
        INSERT INTO HACKATHON_SNOWFLAKE.TRANSPORTATION.TABLE_LOG
        VALUES ('SP_MAINTENANCES', :v_curr_timestamp, 'SUCCESS', 'File(s) found: ' || :v_file_count || ' — Load data successfully');
    
        RETURN '✅ Success: ' || :v_file_count || ' file(s) found and loaded.';

    ELSE
        -- Jika tidak ada file
        INSERT INTO HACKATHON_SNOWFLAKE.TRANSPORTATION.TABLE_LOG
        VALUES ('SP_MAINTENANCES', :v_curr_timestamp, 'SKIPPED', 'No files found in @TRANSPORTATION_INT_STAGE/maintenances/');

        RETURN '⚠️ No files found in @TRANSPORTATION_INT_STAGE/maintenances/. Process skipped.';
    END IF;
    
END;
$$;

