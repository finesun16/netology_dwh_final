CREATE SCHEMA dim; 
CREATE SCHEMA fact;


-- ������� ���������� ��� calendar
CREATE TABLE dim.calendar (
	date_time timestamptz PRIMARY KEY NOT NULL, -- ����-����� - ����
	"date" date  NOT NULL , -- ����
	"month" int4  NOT NULL , -- �����
	YEAR int4 NOT NULL, -- ���
	n_week int4 NOT NULL, -- ������
	day_week varchar(10) NOT NULL-- ���� ������
);

-- ��������� ���������� ��� calendar �������� SQL
INSERT INTO dim.calendar(date_time, "date", "month", "year", n_week, day_week)
SELECT gs AS date_time, gs::date, date_part('month', gs), date_part('year', gs), date_part('week', gs), to_char(gs, 'day')
FROM generate_series('2016-09-13', current_date, interval '1 minute') as gs; 
-- 2016-09-13 - ��� ���� � ������� �������. ���� ���� ����� ������� �� ��� ������, ���� ������ ����� �����������.


--DROP TABLE dim.passengers cascade;
--TRUNCATE  dim.passengers cascade;
-- ������� ���������� ���������� passengers
CREATE TABLE dim.passengers (
	passenger_id varchar(20) PRIMARY KEY, -- ���� �������� (bookings.tickets.ticket_no)
	passenger_name text NOT NULL, -- ��� �������� (bookings.tickets.passenger)
	phone  varchar(20), -- �������  ��������� (bookings.tickets.contact_data ->> 'phone')
	email  varchar(150), -- email  ��������� (bookings.tickets.contact_data ->> 'email')
	flight_id int4, -- ID ������ (booking.ticket_flights.flight_id)
	fare_conditions varchar(20), -- ����� (booking.ticket_flights.fare_conditions)
	amount NUMERIC  -- ��������� ������ (booking.ticket_flights.amount)
);

-- ������� ���������� ��������� aircrafts
CREATE TABLE dim.aircrafts (
	aircraft_code bpchar(3) PRIMARY KEY, -- ���� (bookings.aircrafts.aircraft_code)
	model varchar(20) NOT NULL, -- ������ (bookings.aircrafts.model)
	manufacturer varchar(20) NOT NULL, -- ������������� - ������ ����� � ��������  	
	"range" int4 NOT NULL -- ���������� (bookings.aircrafts."range")
);


-- ������� ���������� ���������� airports
CREATE TABLE dim.airports (
	airport_code bpchar(3) PRIMARY KEY, -- ���� (bookings.airports.airport_code)
	airport_name varchar(50) NOT NULL, -- �������� ��������� (bookings.airports.airport_name)
	airport_city varchar(50) NOT NULL, -- ����� ��������� (bookings.airports.city)
	longitude float(8) NOT NULL, -- ������� ������ (bookings.airports.longitude)
	latitude float(8) NOT NULL -- ������ ������ (bookings.airports.latitude)
);


-- ������� ���������� ������� tariff
--drop TABLE dim.tariff ;
CREATE TABLE dim.tariff (
	fare_conditions varchar(10) PRIMARY KEY -- ����-����� (bookings.seats.fare_conditions)
);

-- ������� ���������� ��������� flights
--DROP TABLE dim.flights;
CREATE TABLE dim.flights (
	flight_id int4 PRIMARY KEY, -- ���� (bookings.flights.flight_id)
	flight_no bpchar(6), -- ����� ����� (bookings.flights.flight_no)
	actual_departure timestamp, -- ���� � ����� ������ (bookings.flights.actual_departure)
	actual_arrival timestamp, -- ���� � ����� ������� (bookings.flights.actual_arrival)
	scheduled_departure timestamp, -- ���� � ����� ������ (bookings.flights.scheduled_departure)
	scheduled_arrival timestamp, -- ���� � ����� ������� (bookings.flights.scheduled_arrival)
	delay_time_departure int4, -- �������� ������ (������� ����� ����������� � ��������������� ����� � ��������) (bookings.flights.actual_departure - bookings.flights.scheduled_departure)
	delay_time_arrival int4, -- �������� ������� (������� ����� ����������� � ��������������� ����� � ��������) (bookings.flights.actual_arrival - bookings.flights.scheduled_arrival)
	aircraft_code varchar(30), -- ��� �������� (bookings.flights.aircraft_code)
	airports_departure_code varchar(30), -- �������� ������ (bookings.flights.departure_airports)
	airports_arrival_code varchar(30)  -- �������� ������� (bookings.flights.arrival_airports)
);


--������� ������ Flights - �������� ����������� ��������. 
--���� � ������ ������ ��� ������� ������� � ����������� - ������ ������� ��������� ����������

--DROP TABLE fact.flights;
CREATE TABLE fact.flights (
	flight_no bpchar(6) NOT NULL, -- ������ ����� (flight_no) 
	passenger_id text references dim.passengers(passenger_id), -- �������� (dim.passengers.passenger_id)
	actual_departure timestamp NOT NULL REFERENCES dim.calendar(date_time), -- ���� � ����� ������ (����) (dim.flights.actual_departure)
	actual_arrival timestamp NOT NULL REFERENCES dim.calendar(date_time), -- ���� � ����� ������� (����) (dim.flights.actual_arrival)
	delay_time_departure int4 NOT NULL, -- �������� ������ (������� ����� ����������� � ��������������� ����� � ��������) (dim.flights.delay_time_departure)
	delay_time_arrival int4 NOT NULL, -- �������� ������� (������� ����� ����������� � ��������������� ����� � ��������) (dim.flights.delay_time_arrival)
	aircraft_code varchar(30) NOT NULL REFERENCES dim.aircrafts(aircraft_code), -- ��� �������� (dim.flights.aircraft_code)
	airports_departure_code varchar(30) NOT NULL REFERENCES dim.airports(airport_code), -- �������� ������ (dim.flights.airports_departure)
	airports_arrival_code varchar(30) NOT NULL REFERENCES dim.airports(airport_code),  -- �������� ������� (dim.flights.airports_arrival)
	fare_conditions varchar(10) NOT NULL REFERENCES dim.tariff(fare_conditions), -- ���� ������ ������������ (dim.tariff)
	amount numeric(10,2) -- ��������� (bookings.ticket_flights.amount)
);


--������� ����� � rejected-������� 

--���� ������ rejected-������� ��������� ����� ������ ������������, �� �����������:
--1)	���� �� �������� PRIMARY KEY � FOREIGN KEY
--2)	���� �� �������� ����� ���� �����������
--3)	��������� ���� reason_for_rejection, � ������� ����� ������� ������� ���������� ������ � rejected-�������.


CREATE SCHEMA rejected;

--DROP TABLE rejected.fact_flights;
CREATE TABLE rejected.fact_flights (
	flight_no bpchar(6),
	passenger_id text, 
	actual_departure timestamp ,
actual_arrival timestamp,
delay_time_departure int4,
delay_time_arrival int4,
aircraft_code varchar(30),
airports_departure_code varchar(30),
airports_arrival_code varchar(30),
fare_conditions varchar(10),
amount numeric(10,2),
reason_for_rejection TEXT -- ���� � �������� ����������
);

CREATE TABLE rejected.aircrafts (
aircraft_code bpchar(3),
model varchar(20), 
manufacturer varchar(20), 
"range" int4,
reason_for_rejection TEXT
);

CREATE TABLE rejected.airports (
airport_code bpchar(3), 
airport_name varchar(50),
airport_city varchar(50),
longitude float(8),
latitude float(8),
reason_for_rejection TEXT -- ���� � �������� ����������
);

--DROP TABLE rejected.passengers;
CREATE TABLE rejected.passengers (
passenger_id varchar(20), 
passenger_name text, 
phone  varchar(20), 
email  varchar(150),
flight_id int4,
fare_conditions varchar(20), 
amount NUMERIC,
reason_for_rejection TEXT -- ���� � �������� ����������
);


CREATE TABLE rejected.tariff (
fare_conditions varchar(10),
reason_for_rejection TEXT -- ���� � �������� ����������
);

-- ������� ���������� ��������� flights
--drop TABLE rejected.dim_flights;
CREATE TABLE rejected.dim_flights (
	flight_id int4,
	flight_no bpchar(6),
	actual_departure timestamp,
	actual_arrival timestamp,
	scheduled_departure timestamp, 
	scheduled_arrival timestamp,
	delay_time_departure int4, 
	delay_time_arrival int4, 
	aircraft_code varchar(30), 
	airports_departure_code varchar(30),
	airports_arrival_code varchar(30),  
	reason_for_rejection TEXT -- ���� � �������� ����������
	);

SELECT * FROM dim.passengers p 

SELECT * FROM dim.flights f 