USE portfolio_db;


----------------------------------------- Parent Dimension Tables (no dependencies/ FK) -----------------------------------------

-------------------- Market Segment --------------------
SELECT DISTINCT (market_segment) FROM staging_reservations;

CREATE TABLE market_segment(
	ms_id INT AUTO_INCREMENT PRIMARY KEY,
	ms_name VARCHAR(50) NOT NULL,
	ms_discount DECIMAL(3,2) NOT NULL DEFAULT 0.00
);

INSERT INTO market_segment (ms_name)
SELECT DISTINCT (market_segment)
FROM staging_reservations
WHERE market_segment != 'Undefined';

UPDATE market_segment
SET ms_discount = CASE ms_name
	WHEN 'Direct' THEN 0.1
	WHEN 'Corporate' THEN 0.15
	WHEN 'Online TA' THEN 0.3
	WHEN 'Offline TA/TO' THEN 0.3 
	WHEN 'Complementary' THEN 1 
	WHEN 'Groups' THEN 0.1
	WHEN 'Aviation' THEN 0.2
	ELSE 0.00
END;

SELECT * FROM market_segment;



-------------------- Distribution Channel --------------------
SELECT DISTINCT (distribution_channel) FROM staging_reservations;

CREATE TABLE distribution_channel(
	dc_id INT AUTO_INCREMENT PRIMARY KEY,
	dc_name VARCHAR(50) NOT NULL
);

INSERT INTO distribution_channel (dc_name)
SELECT DISTINCT (distribution_channel)
FROM staging_reservations
WHERE distribution_channel != 'Undefined';

SELECT * FROM distribution_channel;



-------------------- Agent --------------------
CREATE TABLE agent(
	agent_id INT PRIMARY KEY,
	agent_code VARCHAR(10)
);

INSERT INTO agent (agent_id)
SELECT DISTINCT (agent)
FROM staging_reservations
WHERE agent != "";

UPDATE agent
SET agent_code = CONCAT('AG', LPAD(agent_id, 3, '0'));

SELECT * FROM agent;



-------------------- Meal --------------------
SELECT DISTINCT (meal) FROM staging_reservations;

CREATE TABLE meal(
	meal_id INT AUTO_INCREMENT PRIMARY KEY,
	meal_code VARCHAR(2) NOT NULL,
	meal_cost DECIMAL(5,2) NOT NULL DEFAULT 0,
	meal_descr VARCHAR(100) NOT NULL DEFAULT ''
);

INSERT INTO meal (meal_code, meal_cost, meal_descr)
SELECT DISTINCT meal,
	CASE meal
		WHEN 'BB' THEN 12.99
		WHEN 'FB' THEN 21.99
		WHEN 'HB' THEN 17.99
		WHEN 'SC' THEN 35
		ELSE 0.0
	END,
	CASE meal
		WHEN 'BB' THEN 'Bed and Breakfast'
		WHEN 'FB' THEN 'Full Board'
		WHEN 'HB' THEN 'Half Board'
		WHEN 'SC' THEN 'Self Catering'
		ELSE ''
	END
FROM staging_reservations
WHERE meal != 'Undefined';

SELECT * FROM meal;



-------------------- Customer Type --------------------
SELECT DISTINCT (customer_type) FROM staging_reservations;

CREATE TABLE customer_type (
	ct_id INT AUTO_INCREMENT PRIMARY KEY,
	ct_code VARCHAR(50) NOT NULL
);

INSERT INTO customer_type(ct_code)
SELECT DISTINCT (customer_type)
FROM staging_reservations;

SELECT * FROM customer_type;



-------------------- Country --------------------
# does not need transforming because it's directly imported Alpha-3 country codes



-------------------- Hotel --------------------
SELECT DISTINCT (hotel) FROM staging_reservations;

CREATE TABLE hotel(
	hotel_id INT AUTO_INCREMENT PRIMARY KEY,
	hotel_name VARCHAR(100) NOT NULL
);

INSERT INTO hotel(hotel_name)
SELECT DISTINCT hotel
FROM staging_reservations;

SELECT * FROM hotel;




----------------------------------------- Child Dimension Table (with dependencies/ FK) -----------------------------------------


-------------------- Room Type --------------------

# checking to see if room type codes are repeated across hotels
SELECT 
	reserved_room_type AS room_type, 
	COUNT(DISTINCT hotel) AS hotel_count, 
	GROUP_CONCAT(DISTINCT hotel ORDER BY hotel) AS hotels
FROM staging_reservations
GROUP BY reserved_room_type

UNION

SELECT 
	assigned_room_type AS room_type, 
	COUNT(DISTINCT hotel) AS hotel_count, 
	GROUP_CONCAT(DISTINCT hotel ORDER BY hotel) AS hotels
FROM staging_reservations
GROUP BY assigned_room_type;


# room types A, B, C, D, E, F, G, and P were found in both hotels while H, L, I, and K appear only in one hotel
# important to have hotel distinction


CREATE TABLE room_type(
	room_id INT AUTO_INCREMENT PRIMARY KEY,
	room_code VARCHAR(3) NOT NULL,
	hotel_id INT NOT NULL,
	FOREIGN KEY (hotel_id) REFERENCES hotel(hotel_id)
);


INSERT INTO room_type(room_code, hotel_id)
SELECT DISTINCT
	room_type,
	CASE hotel
		WHEN 'Resort Hotel' THEN 1
		WHEN 'City Hotel' THEN 2
	END AS hotel_id
FROM (
	SELECT reserved_room_type  AS room_type, hotel
	FROM staging_reservations
	UNION
	SELECT assigned_room_type AS room_type, hotel
	FROM staging_reservations
) AS combined_room_type;


SELECT * FROM room_type;



-------------------- Company --------------------
SELECT DISTINCT company FROM staging_reservations;

# no other information is known about the company in the dataset 
CREATE TABLE company(
	company_id INT AUTO_INCREMENT PRIMARY KEY
);

INSERT INTO company
SELECT DISTINCT company
FROM staging_reservations
WHERE company != '';

SELECT * FROM company;



-------------------- Customer --------------------
CREATE TABLE customer(
	customer_id INT AUTO_INCREMENT PRIMARY KEY,
	c_first_name VARCHAR(50) NOT NULL,
	c_last_name VARCHAR(50) NOT NULL ,
	c_email VARCHAR(254),
	c_phone_no VARCHAR(20),
	c_credit_last CHAR(4),
	c_completed_book INT DEFAULT 0,
	c_cancelled_book INT DEFAULT 0,
	country_id CHAR(3) DEFAULT NULL,
	FOREIGN KEY (country_id) REFERENCES country(country_id)
);


# checking to see if there are countries in staging_reservations not in ALPHA-3 code format found in country table
SELECT DISTINCT country
FROM staging_reservations
WHERE country IS NOT NULL
AND country NOT IN (SELECT country_id FROM country);
-- CN and TMP are not proper ALPHA-3 code formats thus need to be converted into CHN and TLS at import


# some customer names have titles (Dr. Mrs. Ms. Mr.) and suffixes (MD, DDS, DVM)... not always in the format "first last"
SELECT name, email, (LENGTH(name) - LENGTH(REPLACE(name, ' ', '')) + 1) AS word_count
FROM staging_reservations sr 
WHERE (LENGTH(name) - LENGTH(REPLACE(name, ' ', '')) + 1) > 2;		-- displays names longer than two words


# adjusting for common prefixes and suffixes
SELECT sr.first_name, sr.last_name, COUNT(*) AS occurrences
FROM (
	SELECT 	SUBSTRING_INDEX(REGEXP_REPLACE(sr.name, '^(Mr\\.?|Mrs\\.?|Ms\\.?|Miss|Dr\\.?|Prof\\.?|Sir|Madam)\\s+', ''), ' ', 1) AS first_name,  -- remove prefix at start
			SUBSTRING_INDEX(REGEXP_REPLACE(sr.name, '\\s+(Jr\\.?|Sr\\.?|II|III|IV|MD|PhD|DVM|DDS|Esq\\.)$', ''), ' ', -1) AS last_name				-- remove suffix at end
	FROM staging_reservations sr
) AS sr
GROUP BY sr.first_name , sr.last_name 
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;;


# name and email combination was used to define unique customers
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT CONCAT(name, '_', email)) AS distinct_customers
FROM staging_reservations;


# reservation occurences and total_bookings don't match because customer information was artificially modified in the dataset for privacy (by the creator of the dataset)
SELECT name, email, COUNT(*) AS occurences, SUM(previous_bookings_not_canceled + previous_cancellations) AS total_bookings
FROM staging_reservations
GROUP BY name, email
HAVING occurences > 1
ORDER BY total_bookings DESC;


# outputs only 3 digits so there probably are some hidden characters at the end
SELECT RIGHT(TRIM(credit_card), 4) FROM staging_reservations;

# adjusting for non numeric values
SELECT RIGHT(REGEXP_REPLACE(credit_card, '[^0-9]', ''), 4) AS credit_number
FROM staging_reservations;


# inserting all customer information accounting for the ff:
#   1. non numeric digits in credit card
#   2. incorrect country code formats
#   3. prefix and suffix in names

INSERT INTO customer(c_first_name, c_last_name, c_email, c_phone_no, c_credit_last, c_completed_book, c_cancelled_book, country_id)
SELECT 
	sr.first_name,
	sr.last_name,
	email,
	phone_number,
	RIGHT(REGEXP_REPLACE(credit_card, '[^0-9]', ''), 4) AS c_credit_last,    -- removes any non numeric values
	previous_bookings_not_canceled,
	previous_cancellations,
	CASE country
		WHEN 'CN' THEN 'CHN'
		WHEN 'TMP' THEN 'TLS'
		WHEN '' THEN NULL 
		ELSE country
	END 
FROM 
	(SELECT 
		*, 
		ROW_NUMBER() OVER (PARTITION BY name, email ORDER BY previous_bookings_not_canceled + previous_cancellations DESC) AS rn,			-- ensures only one record per customer is imported
		SUBSTRING_INDEX(REGEXP_REPLACE(sr.name, '^(Mr\\.?|Mrs\\.?|Ms\\.?|Miss|Dr\\.?|Prof\\.?|Sir|Madam)\\s+', ''), ' ', 1) AS first_name,  -- remove prefix at start
		SUBSTRING_INDEX(REGEXP_REPLACE(sr.name, '\\s+(Jr\\.?|Sr\\.?|II|III|IV|MD|PhD|DVM|DDS|Esq\\.)$', ''), ' ', -1) AS last_name				-- remove suffix at end
		FROM staging_reservations sr
	) AS sr
WHERE sr.rn = 1;


SELECT * FROM customer;




-------------------- reservation_room --------------------

# if relationship between reservations and room are many to many, it would need a junction table so that a reservation can be associated with multiple rooms

# checking if customers at distinct arrival dates are associated with more than one reserved/assigned room
SELECT sr.name, sr.email, sr.arrival_date_year, sr.arrival_date_month, sr.arrival_date_day_of_month,
       COUNT(DISTINCT sr.reserved_room_type) AS distinct_reserved_types,
       COUNT(DISTINCT sr.assigned_room_type) AS distinct_assigned_types
FROM staging_reservations sr
GROUP BY sr.name, sr.email, sr.arrival_date_year, sr.arrival_date_month, sr.arrival_date_day_of_month
HAVING distinct_reserved_types > 1 OR distinct_assigned_types > 1;

-- relationship between customer and room can be found to be N:1
-- so instead of creating a junction table, assigned room and reserved room are added as an attribute of reservation

# this would be the table for reservation_room junction table if a many to many relationship was followed in the original dataset
CREATE TABLE reservation_room(
	reservation_id INT,
	reserved_room INT,
	assigned_room INT,
	PRIMARY KEY (reservation_id, reserved_room),
	FOREIGN KEY (reservation_id) REFERENCES reservation(reservation_id),
	FOREIGN KEY (reserved_room) REFERENCES room_type(room_id),
	FOREIGN KEY (assigned_room) REFERENCES room_type(room_id)
);

# in a real production ready database, a junction table would be needed to facilitate an M:N relationship between customers and room










	






















