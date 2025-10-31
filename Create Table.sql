
-- CREATE TABLE

CREATE OR REPLACE TABLE HACKATHON_SNOWFLAKE.TRANSPORTATION.vehicle_telemetry_complete (
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
from maintenances m
inner join cars c
on c.car_id = m.car_id

---------------------------------------

