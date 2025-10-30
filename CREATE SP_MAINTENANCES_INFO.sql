CREATE OR REPLACE PROCEDURE HACKATHON_SNOWFLAKE.TRANSPORTATION.SP_MAINTENANCES_INFO()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    v_curr_timestamp TIMESTAMP;
BEGIN
    v_curr_timestamp := CONVERT_TIMEZONE('Asia/Jakarta', CURRENT_TIMESTAMP());
    -- Hapus data lama
    -- TRUNCATE TABLE HACKATHON_SNOWFLAKE.TRANSPORTATION.MAINTENANCES_INFO;

    -- insert into ke tabel utama
    INSERT INTO HACKATHON_SNOWFLAKE.TRANSPORTATION.MAINTENANCES_INFO
    select m.*, c.license_plate, c.transmission, c.brand, c.model, c.year, c.fuel_type
    from maintenances m
    inner join cars c
    on c.car_id = m.car_id
    WHERE 1=1
    AND m.maintenance_id not in (
        select distinct maintenance_id from HACKATHON_SNOWFLAKE.TRANSPORTATION.MAINTENANCES_INFO
    )
    ;

    -- Insert log eksekusi
    INSERT INTO HACKATHON_SNOWFLAKE.TRANSPORTATION.TABLE_LOG
    VALUES ('SP_MAINTENANCES_INFO', :v_curr_timestamp, 'SUCCESS', 'Data refreshed successfully');

    RETURN '✅ Refresh completed successfully.';
EXCEPTION
    WHEN OTHER THEN
        INSERT INTO HACKATHON_SNOWFLAKE.TRANSPORTATION.TABLE_LOG
        VALUES ('SP_MAINTENANCES_INFO', :v_curr_timestamp, 'FAILED', 'Error during refresh: ' || ERROR_MESSAGE());
        RETURN '❌ Refresh failed: ' || ERROR_MESSAGE();
END;
$$;

