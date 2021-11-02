CREATE SCHEMA dim; 
CREATE SCHEMA fact;


-- создаем справочник дат calendar
CREATE TABLE dim.calendar (
--	id bigint PRIMARY KEY, -- ключ
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



-- создаем справочник пассажиров passengers
CREATE TABLE dim.passengers (
	passenger_id varchar(20) PRIMARY KEY, -- ключ пасажира (bookings.tickets.passenger_id)
	passenger_name text NOT NULL, -- ФИО пасажира (bookings.tickets.passenger)
	phone  varchar(20), -- телефон  пассажира (bookings.tickets.contact_data ->> 'phone')
	email  varchar(150) -- email  пассажира (bookings.tickets.contact_data ->> 'email')
);

-- создаем справочник самолетов aircrafts
CREATE TABLE dim.aircrafts (
	aircraft_code bpchar(3) PRIMARY KEY, -- ключ (bookings.aircrafts.aircraft_code)
	model varchar(20) NOT NULL, -- модель (bookings.aircrafts.model)
	manufacturer varchar(20) NOT NULL, -- производитель - первое слово в названии  модели самолета 
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
CREATE TABLE dim.tariff (
	fare_conditions_id serial PRIMARY KEY, -- ключ тарифа - не задан, задаем сами
	fare_conditions varchar(10) NOT NULL -- тариф (bookings.seats.fare_conditions)
);





--таблица фактов Flights - содержит совершенные перелеты. 
--Если в рамках билета был сложный маршрут с пересадками - каждый сегмент учитываем независимо

--DROP TABLE fact.flights;
CREATE TABLE fact.flights (
	flight_no bpchar(6) NOT NULL, -- в задании не указано поле с номером рейса, но совокупность номера рейса (flight_no) и даты отправления (scheduled_departure или actual_departure) 
	--являются естественным ключом, поэтому добавление данного поля упростит работу конечного пользователя с таблицей фактов
	passenger_id text references dim.passengers(passenger_id), -- Пассажир (bookings.tickets.passenger_name)
	actual_departure timestamp NOT NULL REFERENCES dim.calendar(date_time), -- Дата и время вылета (факт) (bookings.flights.actual_departure)
	actual_arrival timestamp NOT NULL REFERENCES dim.calendar(date_time), -- Дата и время прилета (факт) (bookings.flights.actual_arrival)
	delay_time_departure int4 NOT NULL, -- Задержка вылета (разница между фактической и запланированной датой в секундах) (bookings.flights.actual_departure - bookings.flights.scheduled_departure)
	delay_time_arrival int4 NOT NULL, -- Задержка прилета (разница между фактической и запланированной датой в секундах) (bookings.flights.actual_arrival - bookings.flights.scheduled_arrival)
	aircraft_code varchar(30) NOT NULL REFERENCES dim.aircrafts(aircraft_code), -- код самолета (bookings.flights.aircraft_code)
	airports_departure_code varchar(30) NOT NULL REFERENCES dim.airports(airport_code), -- Аэропорт вылета (bookings.flights.airports_departure)
	airports_arrival_code varchar(30) NOT NULL REFERENCES dim.airports(airport_code),  -- Аэропорт прилета (bookings.flights.airports_arrival)
	fare_conditions_id int REFERENCES dim.tariff(fare_conditions_id), -- ключ класса обслуживания (dim.tariff)
	amount numeric(10,2) -- стоимость (bookings.ticket_flights.amount)
);


--Создаем схему и rejected-таблицы 

--Поля данных rejected-таблицы идентичны полям таблиц справочником, за исключением:
--1)	Поля не содержат PRIMARY KEY и FOREIGN KEY
--2)	Поля не содержат какие либо ограничения
--3)	Тип автоматически сформированных полей serial изменен на int4
--4)	Добавлено поле reason_for_rejection, в которое будет помещна причина отсеивания данных в rejected-таблицы.


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

CREATE TABLE rejected.passengers (
passenger_id varchar(20), 
passenger_name text, 
phone  varchar(20), 
email  varchar(150),
reason_for_rejection TEXT -- поле с причиной отклонения
);


CREATE TABLE rejected.tariff (
fare_conditions varchar(10),
reason_for_rejection TEXT -- поле с причиной отклонения
);



