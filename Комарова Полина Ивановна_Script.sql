-- Вывести распределение (количество) клиентов по сферам деятельности, отсортировав результат по убыванию количества. — (1 балл)
select count(customer_id)
	,job_industry_category
from customers
group by job_industry_category
order by count(customer_id) desc;


--Найти сумму транзакций за каждый месяц по сферам деятельности, отсортировав по месяцам и по сфере деятельности. — (1 балл)
select sum(list_price), job_industry_category, date_part('month', transaction_date) as n_month
from transactions as t
join customers as c on t.customer_id = c.customer_id
group by (job_industry_category, date_part('month', transaction_date))
order by n_month, job_industry_category;

--Вывести количество онлайн-заказов для всех брендов в рамках подтвержденных заказов клиентов из сферы IT. — (1 балл)
select count(transaction_id)
	,brand
from transactions t 
where order_status = 'Approved' and online_order = 'True' and customer_id in (select customer_id from customers c 
	where job_industry_category = 'IT')
group by brand;


--Найти по всем клиентам сумму всех транзакций (list_price), максимум, минимум и количество транзакций, 
--отсортировав результат по убыванию суммы транзакций и количества клиентов. Выполните двумя способами: 
--используя только group by и используя только оконные функции. Сравните результат. — (2 балла)
select customer_id
	,sum(list_price) as sum_of_trans
	,max(list_price) as max_of_trans
	,min(list_price) as min_of_trans
	,count(transaction_id) as count_trans
from transactions t 
group by customer_id
order by sum_of_trans desc;

select customer_id
	,transaction_id
	,sum(list_price) over(partition by customer_id) as sum_of_trans
	,max(list_price) over(partition by customer_id) as max_of_trans
	,min(list_price) over(partition by customer_id) as min_of_trans
	,count(transaction_id) over(partition by customer_id) as count_trans
from transactions t 
order by sum_of_trans desc;
-- (Мы видим, что результаты по customer_id совпадают)


--Найти имена и фамилии клиентов с минимальной/максимальной суммой транзакций за весь период (сумма транзакций не может 
--быть null). Напишите отдельные запросы для минимальной и максимальной суммы. — (2 балла)
create view nt as 
select t.customer_id, c.first_name, c.last_name
	,sum(t.list_price) as sum_of_trans
from transactions t 
full outer join customers c on t.customer_id = c.customer_id
group by t.customer_id,  c.first_name, c.last_name
having sum(list_price) is not null;

select first_name
	,last_name
from nt
where sum_of_trans = (select min(sum_of_trans) from nt);

select first_name
	,last_name
from nt
where sum_of_trans = (select max(sum_of_trans) from nt);


--Вывести только самые первые транзакции клиентов. Решить с помощью оконных функций. — (1 балл)
select customer_id
	,transaction_id
from(
	select customer_id
		,transaction_id
		,row_number () over(partition by customer_id order by transaction_date) as first
	from transactions t
) as subquery
where first = 1;


--Вывести имена, фамилии и профессии клиентов, между соседними транзакциями которых был максимальный интервал (интервал 
--вычисляется в днях) — (2 балла).
with max_tb as (
	select first_name
		,last_name
		,job_title
		,max(diff) as m
	from(
		select first_name
			,last_name
			,job_title
			,transaction_date - lag(transaction_date) over(partition by t.customer_id order by transaction_date) as diff
		from transactions t 
		join customers c on t.customer_id = c.customer_id 
	)
	group by first_name, last_name, job_title
	having max(diff) is not null
)
select *
from max_tb
where m = (select max(m) from max_tb)