CREATE SCHEMA dim; 
CREATE SCHEMA fact;


-- ������� ���������� ��� calendar
CREATE TABLE dim.calendar (
--	id bigint PRIMARY KEY, -- ����
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



-- ������� ���������� ���������� passengers
CREATE TABLE dim.passengers (
	passenger_id varchar(20) PRIMARY KEY, -- ���� �������� (bookings.tickets.passenger_id)
	passenger_name text NOT NULL, -- ��� �������� (bookings.tickets.passenger)
	phone  varchar(20), -- �������  ��������� (bookings.tickets.contact_data ->> 'phone')
	email  varchar(150) -- email  ��������� (bookings.tickets.contact_data ->> 'email')
);

-- ������� ���������� ��������� aircrafts
CREATE TABLE dim.aircrafts (
	aircraft_code bpchar(3) PRIMARY KEY, -- ���� (bookings.aircrafts.aircraft_code)
	model varchar(20) NOT NULL, -- ������ (bookings.aircrafts.model)
	manufacturer varchar(20) NOT NULL, -- ������������� - ������ ����� � ��������  ������ �������� 
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
CREATE TABLE dim.tariff (
	fare_conditions_id serial PRIMARY KEY, -- ���� ������ - �� �����, ������ ����
	fare_conditions varchar(10) NOT NULL -- ����� (bookings.seats.fare_conditions)
);





--������� ������ Flights - �������� ����������� ��������. 
--���� � ������ ������ ��� ������� ������� � ����������� - ������ ������� ��������� ����������

--DROP TABLE fact.flights;
CREATE TABLE fact.flights (
	flight_no bpchar(6) NOT NULL, -- � ������� �� ������� ���� � ������� �����, �� ������������ ������ ����� (flight_no) � ���� ����������� (scheduled_departure ��� actual_departure) 
	--�������� ������������ ������, ������� ���������� ������� ���� �������� ������ ��������� ������������ � �������� ������
	passenger_id text references dim.passengers(passenger_id), -- �������� (bookings.tickets.passenger_name)
	actual_departure timestamp NOT NULL REFERENCES dim.calendar(date_time), -- ���� � ����� ������ (����) (bookings.flights.actual_departure)
	actual_arrival timestamp NOT NULL REFERENCES dim.calendar(date_time), -- ���� � ����� ������� (����) (bookings.flights.actual_arrival)
	delay_time_departure int4 NOT NULL, -- �������� ������ (������� ����� ����������� � ��������������� ����� � ��������) (bookings.flights.actual_departure - bookings.flights.scheduled_departure)
	delay_time_arrival int4 NOT NULL, -- �������� ������� (������� ����� ����������� � ��������������� ����� � ��������) (bookings.flights.actual_arrival - bookings.flights.scheduled_arrival)
	aircraft_code varchar(30) NOT NULL REFERENCES dim.aircrafts(aircraft_code), -- ��� �������� (bookings.flights.aircraft_code)
	airports_departure_code varchar(30) NOT NULL REFERENCES dim.airports(airport_code), -- �������� ������ (bookings.flights.airports_departure)
	airports_arrival_code varchar(30) NOT NULL REFERENCES dim.airports(airport_code),  -- �������� ������� (bookings.flights.airports_arrival)
	fare_conditions_id int REFERENCES dim.tariff(fare_conditions_id), -- ���� ������ ������������ (dim.tariff)
	amount numeric(10,2) -- ��������� (bookings.ticket_flights.amount)
);


--������� ����� � rejected-������� 

--���� ������ rejected-������� ��������� ����� ������ ������������, �� �����������:
--1)	���� �� �������� PRIMARY KEY � FOREIGN KEY
--2)	���� �� �������� ����� ���� �����������
--3)	��� ������������� �������������� ����� serial ������� �� int4
--4)	��������� ���� reason_for_rejection, � ������� ����� ������� ������� ���������� ������ � rejected-�������.


CREATE SCHEMA rejected;

CREATE TABLE rejected.flights (
	flight_no bpchar(6),
	passenger_id text, 
	actual_departure timestamp ,
actual_arrival timestamp,
delay_time_departure int4,
delay_time_arrival int4,
aircraft_code varchar(30),
airports_departure_code varchar(30),
airports_arrival_code varchar(30),
fare_conditions_id int,
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

CREATE TABLE rejected.passengers (
passenger_id varchar(20), 
passenger_name text, 
phone  varchar(20), 
email  varchar(150),
reason_for_rejection TEXT -- ���� � �������� ����������
);


CREATE TABLE rejected.tariff (
fare_conditions varchar(10),
reason_for_rejection TEXT -- ���� � �������� ����������
);



