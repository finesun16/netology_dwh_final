CREATE SCHEMA dim; 
CREATE SCHEMA fact;


-- создаем справочник дат calendar
CREATE TABLE dim.calendar (
	date_time timestamptz PRIMARY KEY NOT NULL, -- дата-время - ключ
	"date" date  NOT NULL , -- дата
	"month" int4  NOT NULL , -- месяц
	YEAR int4 NOT NULL, -- год
	n_week int4 NOT NULL, -- неделя
	day_week varchar(10) NOT NULL-- день недели
);

-- заполняем справочник дат calendar скриптом SQL
INSERT INTO dim.calendar(date_time, "date", "month", "year", n_week, day_week)
SELECT gs AS date_time, gs::date, date_part('month', gs), date_part('year', gs), date_part('week', gs), to_char(gs, 'day')
FROM generate_series('2016-09-13', current_date, interval '1 minute') as gs; 
-- 2016-09-13 - мин дата в таблице полетов. Макс дата равна текущей на тот случай, если данные будут обновляться.


--DROP TABLE dim.passengers cascade;
--TRUNCATE  dim.passengers cascade;
-- создаем справочник пассажиров passengers
CREATE TABLE dim.passengers (
	passenger_id varchar(20) PRIMARY KEY, -- ключ пасажира (bookings.tickets.ticket_no)
	passenger_name text NOT NULL, -- ФИО пасажира (bookings.tickets.passenger)
	phone  varchar(20), -- телефон  пассажира (bookings.tickets.contact_data ->> 'phone')
	email  varchar(150), -- email  пассажира (bookings.tickets.contact_data ->> 'email')
	flight_id int4, -- ID вылета (booking.ticket_flights.flight_id)
	fare_conditions varchar(20), -- класс (booking.ticket_flights.fare_conditions)
	amount NUMERIC  -- стоимость билета (booking.ticket_flights.amount)
);

-- создаем справочник самолетов aircrafts
CREATE TABLE dim.aircrafts (
	aircraft_code bpchar(3) PRIMARY KEY, -- ключ (bookings.aircrafts.aircraft_code)
	model varchar(20) NOT NULL, -- модель (bookings.aircrafts.model)
	manufacturer varchar(20) NOT NULL, -- производитель - первое слово в названии  	
	"range" int4 NOT NULL -- расстояние (bookings.aircrafts."range")
);


-- создаем справочник аэропортов airports
CREATE TABLE dim.airports (
	airport_code bpchar(3) PRIMARY KEY, -- ключ (bookings.airports.airport_code)
	airport_name varchar(50) NOT NULL, -- название аэропорта (bookings.airports.airport_name)
	airport_city varchar(50) NOT NULL, -- город аэропорта (bookings.airports.city)
	longitude float(8) NOT NULL, -- долгота города (bookings.airports.longitude)
	latitude float(8) NOT NULL -- широта города (bookings.airports.latitude)
);


-- создаем справочник тарифов tariff
--drop TABLE dim.tariff ;
CREATE TABLE dim.tariff (
	fare_conditions varchar(10) PRIMARY KEY -- ключ-тариф (bookings.seats.fare_conditions)
);

-- создаем справочник перелетов flights
--DROP TABLE dim.flights;
CREATE TABLE dim.flights (
	flight_id int4 PRIMARY KEY, -- ключ (bookings.flights.flight_id)
	flight_no bpchar(6), -- номер рейса (bookings.flights.flight_no)
	actual_departure timestamp, -- Дата и время вылета (bookings.flights.actual_departure)
	actual_arrival timestamp, -- Дата и время прилета (bookings.flights.actual_arrival)
	scheduled_departure timestamp, -- Дата и время вылета (bookings.flights.scheduled_departure)
	scheduled_arrival timestamp, -- Дата и время прилета (bookings.flights.scheduled_arrival)
	delay_time_departure int4, -- Задержка вылета (разница между фактической и запланированной датой в секундах) (bookings.flights.actual_departure - bookings.flights.scheduled_departure)
	delay_time_arrival int4, -- Задержка прилета (разница между фактической и запланированной датой в секундах) (bookings.flights.actual_arrival - bookings.flights.scheduled_arrival)
	aircraft_code varchar(30), -- код самолета (bookings.flights.aircraft_code)
	airports_departure_code varchar(30), -- Аэропорт вылета (bookings.flights.departure_airports)
	airports_arrival_code varchar(30)  -- Аэропорт прилета (bookings.flights.arrival_airports)
);


--таблица фактов Flights - содержит совершенные перелеты. 
--Если в рамках билета был сложный маршрут с пересадками - каждый сегмент учитываем независимо

--DROP TABLE fact.flights;
CREATE TABLE fact.flights (
	flight_no bpchar(6) NOT NULL, -- номера рейса (flight_no) 
	passenger_id text references dim.passengers(passenger_id), -- Пассажир (dim.passengers.passenger_id)
	actual_departure timestamp NOT NULL REFERENCES dim.calendar(date_time), -- Дата и время вылета (факт) (dim.flights.actual_departure)
	actual_arrival timestamp NOT NULL REFERENCES dim.calendar(date_time), -- Дата и время прилета (факт) (dim.flights.actual_arrival)
	delay_time_departure int4 NOT NULL, -- Задержка вылета (разница между фактической и запланированной датой в секундах) (dim.flights.delay_time_departure)
	delay_time_arrival int4 NOT NULL, -- Задержка прилета (разница между фактической и запланированной датой в секундах) (dim.flights.delay_time_arrival)
	aircraft_code varchar(30) NOT NULL REFERENCES dim.aircrafts(aircraft_code), -- код самолета (dim.flights.aircraft_code)
	airports_departure_code varchar(30) NOT NULL REFERENCES dim.airports(airport_code), -- Аэропорт вылета (dim.flights.airports_departure)
	airports_arrival_code varchar(30) NOT NULL REFERENCES dim.airports(airport_code),  -- Аэропорт прилета (dim.flights.airports_arrival)
	fare_conditions varchar(10) NOT NULL REFERENCES dim.tariff(fare_conditions), -- ключ класса обслуживания (dim.tariff)
	amount numeric(10,2) -- стоимость (bookings.ticket_flights.amount)
);


--Создаем схему и rejected-таблицы 

--Поля данных rejected-таблицы идентичны полям таблиц справочником, за исключением:
--1)	Поля не содержат PRIMARY KEY и FOREIGN KEY
--2)	Поля не содержат какие либо ограничения
--3)	Добавлено поле reason_for_rejection, в которое будет помещна причина отсеивания данных в rejected-таблицы.


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
reason_for_rejection TEXT -- поле с причиной отклонения
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
reason_for_rejection TEXT -- поле с причиной отклонения
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
reason_for_rejection TEXT -- поле с причиной отклонения
);


CREATE TABLE rejected.tariff (
fare_conditions varchar(10),
reason_for_rejection TEXT -- поле с причиной отклонения
);

-- создаем справочник перелетов flights
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
	reason_for_rejection TEXT -- поле с причиной отклонения
	);

SELECT * FROM dim.passengers p 

SELECT * FROM dim.flights f 