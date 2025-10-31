CREATE OR REPLACE PROCEDURE HACKATHON_SNOWFLAKE.TRANSPORTATION.SP_CARS()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    v_curr_timestamp TIMESTAMP;
    v_file_count NUMBER;
BEGIN
    v_curr_timestamp := CONVERT_TIMEZONE('Asia/Jakarta', CURRENT_TIMESTAMP());

    -- Hitung jumlah file di internal stage folder 'cars/'
    SELECT COUNT(*) 
    INTO v_file_count
    FROM DIRECTORY(@TRANSPORTATION_INT_STAGE)
    WHERE relative_path LIKE 'cars/%'
       OR STARTSWITH(relative_path, 'cars/');

    -- Jika ada file, lanjutkan proses
    IF (v_file_count > 0) THEN
        
        -- Hapus data lama
        TRUNCATE TABLE HACKATHON_SNOWFLAKE.TRANSPORTATION.CARS;

        -- Copy file CSV ke tabel
        COPY INTO HACKATHON_SNOWFLAKE.TRANSPORTATION.CARS
        FROM @TRANSPORTATION_INT_STAGE/cars/
        FILE_FORMAT = (TYPE = 'CSV' FIELD_DELIMITER = ',' SKIP_HEADER = 1)
        PATTERN = '.*\\.csv'
        FORCE = TRUE;

        -- Log sukses
        INSERT INTO HACKATHON_SNOWFLAKE.TRANSPORTATION.TABLE_LOG
        VALUES ('SP_CARS', :v_curr_timestamp, 'SUCCESS', 'File(s) found: ' || :v_file_count || ' — Load data successfully');

        RETURN '✅ Success: ' || :v_file_count || ' file(s) found and loaded.';

    ELSE
        -- Jika tidak ada file
        INSERT INTO HACKATHON_SNOWFLAKE.TRANSPORTATION.TABLE_LOG
        VALUES ('SP_CARS', :v_curr_timestamp, 'SKIPPED', 'No files found in @TRANSPORTATION_INT_STAGE/cars/');

        RETURN '⚠️ No files found in @TRANSPORTATION_INT_STAGE/cars/. Process skipped.';
    END IF;

END;
$$;
