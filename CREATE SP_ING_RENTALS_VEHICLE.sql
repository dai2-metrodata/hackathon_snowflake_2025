CREATE OR REPLACE PROCEDURE HACKATHON_SNOWFLAKE.TRANSPORTATION.SP_ING_RENTALS_VEHICLE(P_NAME_TABLE STRING)
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    v_name_table      STRING;
    result            STRING;
    v_sql             STRING;
    v_curr_timestamp  TIMESTAMP;
BEGIN
    v_name_table     := P_NAME_TABLE;
    v_curr_timestamp := CONVERT_TIMEZONE('Asia/Jakarta', CURRENT_TIMESTAMP());

    IF (LOWER(:v_name_table) = 'vehicle_telemetry') THEN
    
        -- COPY INTO VEHICLE_TELEMETRY
        v_sql := 
        'COPY INTO HACKATHON_SNOWFLAKE.TRANSPORTATION.vehicle_telemetry_complete
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
             FROM @transportation_int_stage/' || v_name_table || '
         )
         FILE_FORMAT = (TYPE = ''CSV'' FIELD_DELIMITER = '','' SKIP_HEADER = 1)
         PATTERN = ''.*/year=.*/month=.*/.*\\.csv''
         FORCE = TRUE
         ON_ERROR = ''SKIP_FILE''';

        EXECUTE IMMEDIATE v_sql;

        INSERT INTO HACKATHON_SNOWFLAKE.TRANSPORTATION.TABLE_LOG
        VALUES ('SP_ING_VEHICLE_TELEMETRY', :v_curr_timestamp, 'SUCCESS', 'Load data ' || :v_name_table || ' successfully');
        
        RETURN '✅ Data ' || :v_name_table || ' loaded successfully from all paths';

    ELSEIF (LOWER(:v_name_table) = 'rentals') THEN

        -- COPY INTO RENTALS
        v_sql := 
        'COPY INTO HACKATHON_SNOWFLAKE.TRANSPORTATION.rentals
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
             FROM @transportation_int_stage/' || v_name_table || '
         )
         FILE_FORMAT = (TYPE = ''CSV'' FIELD_DELIMITER = '','' SKIP_HEADER = 1)
         PATTERN = ''.*/year=.*/month=.*/.*\\.csv''
         FORCE = TRUE
         ON_ERROR = ''SKIP_FILE''';

        EXECUTE IMMEDIATE v_sql;

        INSERT INTO HACKATHON_SNOWFLAKE.TRANSPORTATION.TABLE_LOG
        VALUES ('SP_ING_RENTALS', :v_curr_timestamp, 'SUCCESS', 'Load data ' || :v_name_table || ' successfully');
        
        RETURN '✅ Data ' || :v_name_table || ' loaded successfully from all paths';

    END IF;
    
END;
$$;
