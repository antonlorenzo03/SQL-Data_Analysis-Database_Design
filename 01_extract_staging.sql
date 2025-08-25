CREATE DATABASE portfolio_db;

USE portfolio_db;


----------------------------------------- Staging Table -----------------------------------------

CREATE TABLE staging_reservations (
    hotel VARCHAR(255),
    is_canceled INT,
    lead_time INT,
    arrival_date_year INT,
    arrival_date_month VARCHAR(255),
    arrival_date_week_number INT,
    arrival_date_day_of_month INT,
    stays_in_weekend_nights INT,
    stays_in_week_nights INT,
    adults INT,
    children VARCHAR(255),
    babies VARCHAR(255),
    meal VARCHAR(255),
    country VARCHAR(255),
    market_segment VARCHAR(255),
    distribution_channel VARCHAR(255),
    is_repeated_guest BOOLEAN,
    previous_cancellations INT,
    previous_bookings_not_canceled INT,
    reserved_room_type VARCHAR(255),
    assigned_room_type VARCHAR(255),
    booking_changes INT,
    deposit_type VARCHAR(255),
    agent VARCHAR(255),
    company VARCHAR(255),
    days_in_waiting_list INT,
    customer_type VARCHAR(255),
    adr DECIMAL(10,2),
    required_car_parking_spaces INT,
    total_of_special_requests INT,
    reservation_status VARCHAR(255),
    reservation_status_date VARCHAR(255),
    name VARCHAR(255),
    email VARCHAR(255),
    phone_number VARCHAR(255),
    credit_card VARCHAR(255)
);


CREATE TABLE country(
	country_id CHAR(3) PRIMARY KEY,
	country_name VARCHAR(90)
);


----------------------------------------- Import Data -----------------------------------------

# Import Data
SHOW VARIABLES LIKE 'secure_file_priv';   -- locate directory for csv import

-- Alpha-3 Country Codes
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Country Codes Alpha-2 Alpha-3.csv'
INTO TABLE country
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@country, @alpha2, @alpha3, @numeric)
SET country_id = @alpha3,
	country_name = @country;


-- Hotel Reservation Dataset
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/hotel_booking_dataset.csv'
INTO TABLE staging_reservations
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS




