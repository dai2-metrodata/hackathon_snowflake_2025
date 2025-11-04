create or replace database HACKATHON_SNOWFLAKE;
create or replace schema TRANSPORTATION;

create or replace database SNOWFLAKE_INTELLIGENCE;
create or replace schema AGENTS;

CREATE OR REPLACE NOTIFICATION INTEGRATION my_email_int
  TYPE=EMAIL
  ENABLED=TRUE;

USE DATABASE HACKATHON_SNOWFLAKE;
USE SCHEMA TRANSPORTATION;

ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'aws_us';

CREATE OR REPLACE STAGE transportation_int_stage
  DIRECTORY=(ENABLE=true);


create or replace file format csvformat   
  TYPE = 'CSV'
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1;

  
CREATE OR REPLACE SECRET telegram_bot_token
TYPE = GENERIC_STRING
SECRET_STRING = '7264149561:AAGJgJ7Po1rNzLwGZ3nIHuzpkBHraSHJHqs';

CREATE OR REPLACE SECRET telegram_chat_id
TYPE = GENERIC_STRING
SECRET_STRING = '-4949418789';

CREATE OR REPLACE PROCEDURE "SEND_TELEGRAM_MESSAGE"("MESSAGE_CONTENT" VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS 'DECLARE
    bot_token STRING;
    chat_id STRING;
    telegram_url STRING;
BEGIN
    -- Get credentials (dalam real implementation, pakai secrets)
    bot_token := ''7264149561:AAGJgJ7Po1rNzLwGZ3nIHuzpkBHraSHJHqs'';  -- Ganti dengan token bot Anda
    chat_id := ''-4949418789'';      -- Ganti dengan chat ID Anda
    -- bot_token := ''7843890558:AAE82EQklfB-5YkorVV7EDIUQjG1x8K2jTI'';  -- Ganti dengan token bot Anda
    -- chat_id := ''390461448'';       -- Ganti dengan chat ID Anda

    -- Encode message untuk URL (basic encoding)
    message_content := REPLACE(REPLACE(REPLACE(message_content, '' '', ''%20''), CHR(10), ''%0A''), ''*'', ''%2A'');
    
    -- Build Telegram API URL
    telegram_url := ''https://api.telegram.org/bot'' || bot_token || 
                   ''/sendMessage?chat_id='' || chat_id || 
                   ''&text='' || message_content ||
                   ''&parse_mode=Markdown'';

    -- Return results dengan URL yang siap pakai
    RETURN telegram_url;
END';
    
-- Begin CREATE TABLE

CREATE OR REPLACE TABLE HACKATHON_SNOWFLAKE.TRANSPORTATION.vehicle_telemetry (
    period VARCHAR,
    vehicle_id VARCHAR,
    timestamp TIMESTAMP_NTZ,
    latitude FLOAT,
    longitude FLOAT,
    speed FLOAT,
    battery_level FLOAT,
    odometer FLOAT,
    engine_hours FLOAT,
    fuel_level FLOAT,
    location_address VARCHAR,
    trip_status VARCHAR,
    rental_id VARCHAR
);


CREATE OR REPLACE TABLE HACKATHON_SNOWFLAKE.TRANSPORTATION.customers (
    customer_id VARCHAR,
    customer_name VARCHAR,
    email VARCHAR,
    phone VARCHAR,
    driver_license_number VARCHAR,
    membership_tier VARCHAR,
    registration_date DATE,
    preferred_car_type VARCHAR,
    home_city VARCHAR,
    age_group VARCHAR,
    occupation VARCHAR
);


CREATE OR REPLACE TABLE HACKATHON_SNOWFLAKE.TRANSPORTATION.maintenances (
    maintenance_id VARCHAR,
    car_id VARCHAR,
    maintenance_type VARCHAR,
    maintenance_date DATE,
    cost FLOAT,
    description VARCHAR,
    next_maintenance_date DATE,
    odometer_at_maintenance FLOAT,
    maintenance_status VARCHAR,
    workshop_location VARCHAR
);


CREATE OR REPLACE TABLE HACKATHON_SNOWFLAKE.TRANSPORTATION.cars (
    car_id VARCHAR,
    license_plate VARCHAR,
    brand VARCHAR,
    model VARCHAR,
    year INTEGER,
    color VARCHAR,
    fuel_type VARCHAR,
    daily_rate FLOAT,
    last_maintenance_date DATE,
    next_maintenance_km FLOAT,
    car_type VARCHAR,
    ac_type VARCHAR,
    transmission VARCHAR,
    seating_capacity INTEGER
);



CREATE OR REPLACE TABLE HACKATHON_SNOWFLAKE.TRANSPORTATION.rentals (
    period VARCHAR,
    rental_id VARCHAR,
    car_id VARCHAR,
    customer_id VARCHAR,
    rental_date DATE,
    return_date DATE,
    actual_return_date DATE,
    total_amount FLOAT,
    status VARCHAR,
    rental_duration_days INTEGER,
    pickup_location VARCHAR,
    payment_method VARCHAR
);


CREATE OR REPLACE TABLE HACKATHON_SNOWFLAKE.TRANSPORTATION.TABLE_LOG (
  SP_NAME VARCHAR,
  RUN_AT TIMESTAMP_NTZ,
  STATUS VARCHAR,
  MESSAGE VARCHAR
);


CREATE OR REPLACE TABLE HACKATHON_SNOWFLAKE.TRANSPORTATION.MAINTENANCES_INFO AS
select m.*, c.license_plate, c.transmission, c.brand, c.model, c.year, c.fuel_type
from HACKATHON_SNOWFLAKE.TRANSPORTATION.maintenances m
inner join HACKATHON_SNOWFLAKE.TRANSPORTATION.cars c
on c.car_id = m.car_id
;
-- End CREATE TABLE
    
-- SP Custom Tools send email
CREATE OR REPLACE PROCEDURE "SEND_EMAIL"("RECIPIENT_EMAIL" VARCHAR, "SUBJECT" VARCHAR, "BODY" VARCHAR)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.12'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'send_email'
EXECUTE AS OWNER
AS '
def send_email(session, recipient_email, subject, body):
    try:
        # Escape single quotes in the body
        escaped_body = body.replace("''", "''''")
        
        # Execute the system procedure call
        session.sql(f"""
            CALL SYSTEM$SEND_EMAIL(
                ''my_email_int'',
                ''{recipient_email}'',
                ''{subject}'',
                ''{escaped_body}'',
                ''text/html''
            )
        """).collect()
        
        return "Email sent successfully"
    except Exception as e:
        return f"Error sending email: {str(e)}"
';


    CREATE OR REPLACE MASKING POLICY email_mask_policy AS (val STRING) RETURNS STRING ->
      CASE
        WHEN CURRENT_ROLE() = 'ANALYST_ROLE' THEN '******' || SUBSTRING(val, LENGTH(val) - 4)
        WHEN CURRENT_ROLE() = 'ADMIN_ROLE' or CURRENT_ROLE() = 'ACCOUNTADMIN' THEN val
        ELSE 'MASKED'
      END;
  
    ALTER TABLE customers MODIFY COLUMN email SET MASKING POLICY email_mask_policy;

    
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
    