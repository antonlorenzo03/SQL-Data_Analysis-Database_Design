USE portfolio_db;


CREATE TABLE reservation(
	reservation_id INT AUTO_INCREMENT PRIMARY KEY,
	customer_id INT NOT NULL,
	ms_id INT,
	dc_id INT,
	agent_id INT,
	deposit_type VARCHAR(20) NOT NULL,
	reservation_status VARCHAR(20) NOT NULL,
	reservation_status_date DATE,
	guest_babies INT DEFAULT 0,
	guest_children INT DEFAULT 0,
	guest_adults INT NOT NULL,
	arrival_date DATE NOT NULL ,
	booking_date DATE NOT NULL,
	is_cancelled BOOLEAN NOT NULL DEFAULT 0,
	days_waiting_list INT,
	booking_changes INT DEFAULT 0,
	req_car_parking INT DEFAULT 0,
	special_req INT DEFAULT 0,
	adr DECIMAL(10,2) DEFAULT NULL,
	company_id INT,
	meal_id INT,
	ct_id INT,
	departure_date DATE NOT NULL,
	assigned_room_id INT,
	reserved_room_id INT NOT NULL,
	FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
	FOREIGN KEY (ms_id) REFERENCES market_segment(ms_id),
	FOREIGN KEY (dc_id) REFERENCES distribution_channel(dc_id),
	FOREIGN KEY (agent_id) REFERENCES agent(agent_id),
	FOREIGN KEY (company_id) REFERENCES company(company_id),
	FOREIGN KEY (meal_id) REFERENCES meal(meal_id),
	FOREIGN KEY (ct_id) REFERENCES customer_type(ct_id),
	FOREIGN KEY (assigned_room_id) REFERENCES room_type(room_id),
	FOREIGN KEY (reserved_room_id)REFERENCES room_type(room_id)
);



# testing each foreign key join on staging reservations before making insert statement
SELECT c.customer_id, sr.name
FROM staging_reservations sr LEFT JOIN customer c 
ON c.c_first_name = SUBSTRING_INDEX(sr.name, ' ', 1)
	AND c.c_last_name = SUBSTRING_INDEX(sr.name, ' ', -1)
	AND c.c_email = sr.email;

SELECT ms.ms_id, sr.market_segment
FROM staging_reservations sr LEFT JOIN market_segment ms 
ON ms.ms_name = sr.market_segment;

SELECT dc.dc_id, sr.distribution_channel
FROM staging_reservations sr LEFT JOIN distribution_channel dc 
ON dc.dc_name = sr.distribution_channel;

SELECT a.agent_id, sr.agent
FROM staging_reservations sr LEFT JOIN agent a 
ON a.agent_id = sr.agent;	--- agent_id outputs NULL if no agent was used

SELECT c.company_id, sr.company
FROM staging_reservations sr LEFT JOIN company c 
ON c.company_id = sr.company;	--- company_id outputs NULL if customer is not associated with any company

SELECT m.meal_id, sr.meal
FROM staging_reservations sr LEFT JOIN meal m 
ON m.meal_code = sr.meal;

SELECT ct.ct_id, sr.customer_type
FROM staging_reservations sr LEFT JOIN customer_type ct 
ON ct.ct_code = sr.customer_type;



INSERT INTO reservation (
    customer_id, ms_id, dc_id, agent_id, deposit_type, reservation_status,
    reservation_status_date, guest_babies, guest_children, guest_adults,
    arrival_date, booking_date, is_cancelled, days_waiting_list,
    booking_changes, req_car_parking, special_req, adr, company_id, meal_id, ct_id, departure_date,
    assigned_room_id, reserved_room_id
)
SELECT
	c.customer_id,
	ms.ms_id,
	dc.dc_id,
	a.agent_id,
	sr.deposit_type,
	sr.reservation_status,
	CAST(sr.reservation_status_date AS DATE),
	sr.babies,
	CASE sr.children
		WHEN '' THEN 0
		ELSE sr.children
		END,					-- some rows in children were ' ' rather than 0
	sr.adults,
	STR_TO_DATE(CONCAT(sr.arrival_date_year, '-', sr.arrival_date_month , '-', sr.arrival_date_day_of_month), '%Y-%M-%d'),			-- converting arrival_date_year, arrival_date_month, arrival_date_day_of_month into one date format
	DATE_SUB(STR_TO_DATE(CONCAT(sr.arrival_date_year, '-', sr.arrival_date_month , '-', sr.arrival_date_day_of_month), '%Y-%M-%d'), INTERVAL sr.lead_time DAY),		-- calculating booking date from lead time
	sr.is_canceled,
	sr.days_in_waiting_list,
	sr.booking_changes,
	sr.required_car_parking_spaces,
	sr.total_of_special_requests,
	sr.adr,
	co.company_id,
	m.meal_id,
	ct.ct_id,
	DATE_ADD(STR_TO_DATE(CONCAT(sr.arrival_date_year, '-', sr.arrival_date_month , '-', sr.arrival_date_day_of_month), '%Y-%M-%d'), INTERVAL (sr.stays_in_weekend_nights + sr.stays_in_week_nights) DAY),		-- calculating departure date from length of stay
	rt_assigned.room_id,
	rt_reserved.room_id
FROM 
	staging_reservations sr
	LEFT JOIN customer c
		ON c.c_first_name = SUBSTRING_INDEX(REGEXP_REPLACE(sr.name, '^(Mr\\.?|Mrs\\.?|Ms\\.?|Miss|Dr\\.?|Prof\\.?|Sir|Madam)\\s+', ''), ' ', 1)	-- remove prefix at start
			AND c.c_last_name = SUBSTRING_INDEX(REGEXP_REPLACE(sr.name, '\\s+(Jr\\.?|Sr\\.?|II|III|IV|MD|PhD|DVM|DDS|Esq\\.)$', ''), ' ', -1)		-- remove suffix at end
			AND c.c_email = sr.email
	LEFT JOIN market_segment ms 
		ON ms.ms_name = sr.market_segment
	LEFT JOIN distribution_channel dc 
		ON dc.dc_name = sr.distribution_channel
	LEFT JOIN agent a 
		ON a.agent_id = sr.agent
	LEFT JOIN company co 
		ON co.company_id = sr.company
	LEFT JOIN meal m 
		ON m.meal_code = sr.meal
	LEFT JOIN customer_type ct 
		ON ct.ct_code = sr.customer_type
	LEFT JOIN hotel h
		ON h.hotel_name = sr.hotel
	LEFT JOIN room_type rt_reserved
		ON rt_reserved.room_code = sr.reserved_room_type
		AND rt_reserved.hotel_id = h.hotel_id
	LEFT JOIN room_type rt_assigned
		ON rt_assigned.room_code = sr.assigned_room_type
		AND rt_assigned.hotel_id = h.hotel_id;


# checking if number of rows remain the same (ensuring no dupliactes)
SELECT count(*) FROM staging_reservations sr ;

SELECT count(*) FROM reservation;


SELECT * FROM reservation;







	
	




