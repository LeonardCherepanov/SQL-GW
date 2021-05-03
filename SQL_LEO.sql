
--1. В каких городах больше одного аэропорта?

select city, count(city) 
from airports_data ad
group by 1 --группируем по названию города
having count(city) > 1

--2. В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?
-- Должны присутствовать: Подзапрос

--explain analyse 
select distinct ad.airport_name, ad.airport_code 
from flights f
join airports_data ad on ad.airport_code = f.departure_airport -- джойним таблицу с названиями аэропортов
where aircraft_code in
(select aircraft_code from aircrafts_data order by "range" desc limit 1) -- находим самолет с максимальной дальностью полета (Подзапрос)
--group by 1,2

--3. Вывести 10 рейсов с максимальным временем задержки вылета.
-- Должны присутствовать: Оператор LIMIT

select flight_id, actual_departure - scheduled_departure as delta 
from flights f 
where actual_departure notnull -- фильтруем несостоявшиеся рейсы
order by 2 desc -- фильтруем по времени задержки
limit 10 -- оставляем первые 10 записей (Оператор LIMIT)

--4. Были ли брони, по которым не были получены посадочные талоны? - Верный тип JOIN
-- Да. Такие брони существуют 127 899 забронированных билетов

select t.ticket_no, b_p.ticket_no
from tickets t
left join boarding_passes b_p using (ticket_no)
where b_p.ticket_no is null 


--5. Найдите свободные места для каждого рейса, их % отношение к общему количеству мест в самолете.
/* Свободные места находим путем деления количества мест (проданных билетов) на общее доступное количество, указанное в таблице seats*/
--Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день. 
/* используем date_trunc 'day' для рассмотрения внутри каждого дня. И разумеется, оконную функцию.*/ 
--Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах за день.
--Должны присутствовать: Оконная функция, Подзапросы
/* Рассматриваю только завершенные рейсы, с проданными билетами (как оказалось, есть рейсы, на которые не было продано билетов)*/


select departure_airport, actual_departure, flight_id, c_seats-c_tickets as free_seats, 100*(c_seats-c_tickets)/c_seats as "free_seats_%",
	sum(c_tickets) over (partition by departure_airport, date_trunc('day', actual_departure) order by actual_departure)
from flights
left join ( 
	select flight_id, count(ticket_no) as c_tickets
	from ticket_flights
	group by 1) as t using(flight_id)
left join (
	select aircraft_code, count(seat_no) as c_seats
	from seats s
	group by 1) as s using(aircraft_code)
where (status like 'Arrived') and (c_tickets is not NULL)
order by 1, 2, 3


--6. Найдите процентное соотношение перелетов по типам самолетов от общего количества.
--Должны присутствовать: Подзапрос, оператор ROUND


select model, count(flight_id), round(100*(count(flight_id)/(select count(flight_id) from flights where status not like 'Cancelled')::numeric), 0) as ratio
from flights f
join aircrafts_data ad using (aircraft_code)
where status not like 'Cancelled'
group by 1
order by count desc


--7. Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?
--Должны присутствовать:  CTE
/* Такие недочеты отсутствуют. Самый дешевый бизнес во всех случаях превышает самый дорогой эконом.*/

with max_econom as (
	select flight_id, max(amount) as "max"
	from ticket_flights tf 
	where fare_conditions like 'Economy'
	group by 1),
min_business as (
	select flight_id, min(amount) as "min"
	from ticket_flights tf 
	where fare_conditions like 'Business'
	group by 1)
select city, (select 
	case 
		when "min" > "max" then 'нет'
		when "min" < "max" then 'да'
		else 'равно'
	end) as "выгоднее?"
from max_econom
join min_business using (flight_id)
join flights using (flight_id)
join airports_data a on a.airport_code = arrival_airport
group by 1,2



