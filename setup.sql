create or replace database HACKATHON_SNOWFLAKE;
create or replace schema TRANSPORTATION;

create or replace database SNOWFLAKE_INTELLIGENCE;
create or replace schema AGENTS;

CREATE NOTIFICATION INTEGRATION my_email_int
  TYPE=EMAIL
  ENABLED=TRUE;

ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'aws_us';

CREATE STAGE transportation_int_stage
  DIRECTORY=(ENABLE=true);

CREATE STAGE semantic_models
  DIRECTORY=(ENABLE=true);

CREATE OR REPLACE CORTEX SEARCH SERVICE maintenance_service
ON listing_text
ATTRIBUTES maintenance_type
WAREHOUSE = compute_small
TARGET_LAG = '1 hour'
AS
    SELECT
        maintenance_id,
        car_id,
        maintenance_type,
        maintenance_date,
        cost, 
        next_maintenance_date,
        odometer_at_maintenance,
        maintenance_status,
        workshop_location,
        transmission,
        brand,
        model,
        year,
        fuel_type,
        ('License Plate\n\n' || license_plate || '\n\n\brand\n\n' || brand || '\n\n\model\n\n' || model 
        || '\n\n\year\n\n' || year || '\n\n\fuel_type\n\n' || fuel_type || '\n\transmission\n\n' || transmission || '\n\nDescription\n\n' || description ||  '\n\nMaintenance Status\n\n' || maintenance_status) as listing_text
    FROM MAINTENANCES_INFO;

create or replace table VEHICLE_TELEMATICS(
	YEAR VARCHAR(16777216) ,
	MONTH VARCHAR(16777216),
	VEHICLE_ID_PARTITION VARCHAR(16777216) ,
	VEHICLE_ID NUMBER(38,0),
	COORDINATE_ID VARCHAR(16777216),
	ROW_NUM NUMBER(38,0),
	LATITUDE FLOAT,
	LONGITUDE FLOAT,
	ALTITUDE_R NUMBER(38,0),
	HEADING_R NUMBER(38,0) ,
	INSTANTANEOUS_SPEED_R NUMBER(38,0),
	BATTERY_LEVEL_R FLOAT ,
	CUMULATED_RAW_ODOMETER FLOAT,
	CUMULATED_RAW_ENGINE_HRS NUMBER(38,0),
	TRIP_ID NUMBER(38,0),
	START_TIME TIMESTAMP_NTZ(9),
	END_TIME TIMESTAMP_NTZ(9) ,
	IDLE_TIME NUMBER(38,0),
	IDLE_COUNT NUMBER(38,0) ,
	TURN_ON_KEY NUMBER(38,0) ,
	TURN_OFF_KEY NUMBER(38,0) ,
	GPS_DISTANCE FLOAT ,
	INSTANTANEOUS_SPEED NUMBER(38,0) ,
	ODOMETER_CHANGE FLOAT,
	ENGINE_HRS NUMBER(38,0) ,
	DURATION_SECONDS NUMBER(38,0) ,
	OFF_TIME NUMBER(38,0),
	ON_TIME NUMBER(38,0),
	START_TIMESTAMP TIMESTAMP_NTZ(9) )

;

create or replace file format csvformat   
  TYPE = 'CSV'
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1;

  
COPY INTO VEHICLE_TELEMATICS
FROM '@"HACKATHON_SNOWFLAKE"."TRANSPORTATION"."TRANSPORTATION_INT_STAGE"/SOR_FACT_POSITION_MESSAGE_BY_COORDINATE.csv'
FILE_FORMAT = csvformat;



CREATE OR REPLACE SECRET telegram_bot_token
TYPE = GENERIC_STRING
SECRET_STRING = '7264149561:AAGJgJ7Po1rNzLwGZ3nIHuzpkBHraSHJHqs';

CREATE OR REPLACE SECRET telegram_chat_id
TYPE = GENERIC_STRING
SECRET_STRING = '8229024390';

-- Custom tool untuk kirim pesan ke Telegram
CREATE OR REPLACE PROCEDURE send_telegram_message(
    message_content STRING
)
RETURNS STRING
LANGUAGE SQL
AS
DECLARE
    bot_token STRING;
    chat_id STRING;
    telegram_url STRING;
BEGIN
    -- Get credentials (dalam real implementation, pakai secrets)
    bot_token := '7264149561:AAGJgJ7Po1rNzLwGZ3nIHuzpkBHraSHJHqs';  -- Ganti dengan token bot Anda
    chat_id := '8229024390';      -- Ganti dengan chat ID Anda

    -- Encode message untuk URL (basic encoding)
    message_content := REPLACE(REPLACE(REPLACE(message_content, ' ', '%20'), CHR(10), '%0A'), '*', '%2A');
    
    -- Build Telegram API URL
    telegram_url := 'https://api.telegram.org/bot' || bot_token || 
                   '/sendMessage?chat_id=' || chat_id || 
                   '&text=' || message_content ||
                   '&parse_mode=Markdown';

    -- Return results dengan URL yang siap pakai
    RETURN telegram_url;
END;

call send_telegram_message('halo')

call send_email()

select analyze_fleet_utilization('last_2_month')


    CREATE OR REPLACE MASKING POLICY email_mask_policy AS (val STRING) RETURNS STRING ->
      CASE
        WHEN CURRENT_ROLE() = 'ANALYST_ROLE' THEN '******' || SUBSTRING(val, LENGTH(val) - 4)
        WHEN CURRENT_ROLE() = 'ADMIN_ROLE' or CURRENT_ROLE() = 'ACCOUNTADMIN' THEN val
        ELSE 'MASKED'
      END;
  
    ALTER TABLE customers MODIFY COLUMN email SET MASKING POLICY email_mask_policy;\

    
    CREATE OR REPLACE MASKING POLICY phone_mask_policy AS (val STRING) RETURNS STRING ->
      CASE
        WHEN CURRENT_ROLE() = 'ANALYST_ROLE' THEN '*******' || SUBSTRING(val, LENGTH(val) - 4)
        WHEN CURRENT_ROLE() = 'ADMIN_ROLE' or CURRENT_ROLE() = 'ACCOUNTADMIN' THEN val
        ELSE 'MASKED'
      END;
 
  
    ALTER TABLE customers MODIFY COLUMN phone SET MASKING POLICY phone_mask_policy;

    
    CREATE OR REPLACE MASKING POLICY driver_license_mask_policy AS (val STRING) RETURNS STRING ->
      CASE
        WHEN CURRENT_ROLE() = 'ANALYST_ROLE' THEN '**********' || SUBSTRING(val, LENGTH(val) - 4)
        WHEN CURRENT_ROLE() = 'ADMIN_ROLE' or CURRENT_ROLE() = 'ACCOUNTADMIN' THEN val
        ELSE 'MASKED'
      END;
  
    ALTER TABLE customers MODIFY COLUMN driver_license_number SET MASKING POLICY driver_license_mask_policy;

    create or replace role ANALYST_ROLE;
    create or replace role ADMIN_ROLE;
    
    use role accountadmin;
    
    CREATE USER beni
    PASSWORD = 'SecurePassword123!'
    DEFAULT_ROLE = 'ADMIN_ROLE'
    DEFAULT_WAREHOUSE = 'COMPUTE_WH';

    grant role ADMIN_ROLE to user beni;
    grant usage on database hackathon_snowflake to role ADMIN_ROLE;
    grant usage on schema TRANSPORTATION to role ADMIN_ROLE;
    GRANT SELECT ON ALL TABLES IN schema TRANSPORTATION TO ROLE ADMIN_ROLE;
    GRANT USAGE ON ALL CORTEX SEARCH SERVICES IN schema TRANSPORTATION TO ROLE ADMIN_ROLE;
    GRANT ALL ON ALL SEMANTIC VIEWS IN schema TRANSPORTATION TO ROLE ADMIN_ROLE;
    GRANT USAGE ON ALL PROCEDURES IN schema TRANSPORTATION TO ROLE ADMIN_ROLE;
    GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ADMIN_ROLE;
    
    grant usage on database SNOWFLAKE_INTELLIGENCE to role ADMIN_ROLE;
    grant usage on schema SNOWFLAKE_INTELLIGENCE.AGENTS to role ADMIN_ROLE;
    GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.SMARTFLEETMONITORINGAGENT to ROLE ADMIN_ROLE;

    CREATE USER siska
    PASSWORD = 'SecurePassword123!'
    DEFAULT_ROLE = 'ANALYST_ROLE'
    DEFAULT_WAREHOUSE = 'COMPUTE_WH';

    grant role ANALYST_ROLE to user siska;
    grant usage on database hackathon_snowflake to role ANALYST_ROLE;
    grant usage on schema TRANSPORTATION to role ANALYST_ROLE;
    GRANT SELECT ON ALL TABLES IN schema TRANSPORTATION TO ROLE ANALYST_ROLE;
    GRANT USAGE ON ALL CORTEX SEARCH SERVICES IN schema TRANSPORTATION TO ROLE ANALYST_ROLE;
    GRANT ALL ON ALL SEMANTIC VIEWS IN schema TRANSPORTATION TO ROLE ANALYST_ROLE;
    GRANT USAGE ON ALL PROCEDURES IN schema TRANSPORTATION TO ROLE ANALYST_ROLE;
    GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ANALYST_ROLE;
    
    grant usage on database SNOWFLAKE_INTELLIGENCE to role ANALYST_ROLE;
    grant usage on schema SNOWFLAKE_INTELLIGENCE.AGENTS to role ANALYST_ROLE;
    GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.SMARTFLEETMONITORINGAGENT to ROLE ANALYST_ROLE;

    CREATE OR REPLACE API INTEGRATION my_git_api_integration
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/dai2-metrodata/')
    API_USER_AUTHENTICATION = (
    TYPE = snowflake_github_app
    )
    ENABLED = TRUE;
    
    
 


