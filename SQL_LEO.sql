
--1. � ����� ������� ������ ������ ���������?

select city, count(city) 
from airports_data ad
group by 1 --���������� �� �������� ������
having count(city) > 1

--2. � ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������?
-- ������ ��������������: ���������

--explain analyse 
select distinct ad.airport_name, ad.airport_code 
from flights f
join airports_data ad on ad.airport_code = f.departure_airport -- ������� ������� � ���������� ����������
where aircraft_code in
(select aircraft_code from aircrafts_data order by "range" desc limit 1) -- ������� ������� � ������������ ���������� ������ (���������)
--group by 1,2

--3. ������� 10 ������ � ������������ �������� �������� ������.
-- ������ ��������������: �������� LIMIT

select flight_id, actual_departure - scheduled_departure as delta 
from flights f 
where actual_departure notnull -- ��������� �������������� �����
order by 2 desc -- ��������� �� ������� ��������
limit 10 -- ��������� ������ 10 ������� (�������� LIMIT)

--4. ���� �� �����, �� ������� �� ���� �������� ���������� ������? - ������ ��� JOIN
-- ��. ����� ����� ���������� 127 899 ��������������� �������

select t.ticket_no, b_p.ticket_no
from tickets t
left join boarding_passes b_p using (ticket_no)
where b_p.ticket_no is null 


--5. ������� ��������� ����� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������.
/* ��������� ����� ������� ����� ������� ���������� ���� (��������� �������) �� ����� ��������� ����������, ��������� � ������� seats*/
--�������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� ���������� �� ������� ��������� �� ������ ����. 
/* ���������� date_trunc 'day' ��� ������������ ������ ������� ���. � ����������, ������� �������.*/ 
--�.�. � ���� ������� ������ ���������� ������������� ����� - ������� ������� ��� �������� �� ������� ��������� �� ���� ��� ����� ������ ������ �� ����.
--������ ��������������: ������� �������, ����������
/* ������������ ������ ����������� �����, � ���������� �������� (��� ���������, ���� �����, �� ������� �� ���� ������� �������)*/


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


--6. ������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������.
--������ ��������������: ���������, �������� ROUND


select model, count(flight_id), round(100*(count(flight_id)/(select count(flight_id) from flights where status not like 'Cancelled')::numeric), 0) as ratio
from flights f
join aircrafts_data ad using (aircraft_code)
where status not like 'Cancelled'
group by 1
order by count desc


--7. ���� �� ������, � ������� �����  ��������� ������ - ������� �������, ��� ������-������� � ������ ��������?
--������ ��������������:  CTE
/* ����� �������� �����������. ����� ������� ������ �� ���� ������� ��������� ����� ������� ������.*/

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
		when "min" > "max" then '���'
		when "min" < "max" then '��'
		else '�����'
	end) as "��������?"
from max_econom
join min_business using (flight_id)
join flights using (flight_id)
join airports_data a on a.airport_code = arrival_airport
group by 1,2



