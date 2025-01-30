End to End project on 'Online Banking' using SQL, Python (ETL), Power BI
                                  KPI ↓

→ 1. How many unique customers are there?
→ 2. How many unique customers are coming from each region?
→ 3. How many unique customers are coming from each area?
→ 4. What is the total amount for each transaction type?
→ 5. For each month - how many customers make more than 1 deposit and 1 withdrawal in a single month?
→ 6. What is closing balance for each customer?
→ 7. What is the closing balance for each customer at the end of the month?
→ 8. Please show the latest 5 days total withdraw amount.
→ 9. Find out the total deposit amount for every five days consecutive series. You can assume 1 week = 5 days. 
	 Please show the result week wise total amount.
→ 10. Plaase compare every weeks total deposit amount by the following previous wweek. 
	  Example: Week 1 will be compared with Week 2 [Calculation Week2 - Week 1]-> Next week - previous week
		Week 2 will be compared with Week 3  [Calculation Week3 - Week 2]
		
→ 11. Forecast (15Days) total deposit & withdrawal amount?

-----------------------------------------------------------------------------------
→ Table Details:

select * from customer_transactions 

select * from customer_joining_info 

select * from area 

select * from region

-----------------------------------------------------------------------------------
1. How many unique customers are there?

select count(distinct (customer_id)) as total_unique_customers
from customer_transactions;

↓

with unique_customer as (
    select count(distinct (customer_id)) as total_unique_customers
    from customer_transactions
	)
select total_unique_customers
FROM unique_customer;

-----------------------------------------------------------------------------------
2. How many unique customers are coming from each region?

select r.region_id ,r.region_name , t.total_unique_customers
from 
(
select cj.region_id, count(distinct (customer_id)) as total_unique_customers
from customer_joining_info as cj
group by region_id
) as t
inner join region as r
on t.region_id = r.region_id
order by total_unique_customers desc ;

select *
from area a 

-----------------------------------------------------------------------------------
3. How many unique customers are coming from each area?

select t2.area_id, a.name , t2.quantity
from 
(
select  area_id, count(customer_id) as quantity
from
(
select 
    customer_id, area_id,
    row_number () over (partition by customer_id order by join_date) as rn
from customer_joining_info
) as t
where rn = 1
group by area_id
) as t2
inner join area a
on a.area_id = t2.area_id

-----------------------------------------------------------------------------------
4. What is the total amount for each transaction type?

select txn_type , sum(txn_amount) as total_amount
from customer_transactions
group by txn_type 


select *
from customer_transactions ct 
-----------------------------------------------------------------------------------
4.1 What is the total amount for each transaction type and total balance ?

select 
	sum( case when txn_type = 'deposit' then txn_amount else 0 end) as deposit_amount,
	sum( case when txn_type = 'withdrawal' then txn_amount else 0 end) as withdraw_amount,
		(sum( case when txn_type = 'deposit' then txn_amount else 0 end) -
			sum( case when txn_type = 'withdrawal' then txn_amount else 0 end)) as total_balance,
		((sum( case when txn_type = 'deposit' then txn_amount else 0 end) -
			sum( case when txn_type = 'withdrawal' then txn_amount else 0 end))) / 
				(sum( case when txn_type = 'deposit' then txn_amount else 0 end)) as balance_per			
from customer_transactions

---------------
4.1.1
select txn_date ,
	sum( case when txn_type = 'deposit' then txn_amount else 0 end) as deposit_amount,
	sum( case when txn_type = 'withdrawal' then txn_amount else 0 end) as withdraw_amount,
		(sum( case when txn_type = 'deposit' then txn_amount else 0 end) -
			sum( case when txn_type = 'withdrawal' then txn_amount else 0 end)) as total_balance,
		((sum( case when txn_type = 'deposit' then txn_amount else 0 end) -
			sum( case when txn_type = 'withdrawal' then txn_amount else 0 end))) / 
				(sum( case when txn_type = 'deposit' then txn_amount else 0 end)) as balance_per			
from customer_transactions
group by txn_date 

-----------------------------------------------------------------------------------
5. For each month - how many customers make more than 1 deposit and 1 withdrawal in a single month?


select t2.month_no, count( customer_id) as customer
from 
(
select *
from 
(
	select month(txn_date) as month_no , customer_id, 
	 count( case when txn_type = 'deposit' then txn_type end) as deposit_qty,
	 count( case when txn_type = 'withdrawal' then txn_type end) as withdrawal_qty
	from customer_transactions
	group by customer_id,month(txn_date)
	order by  month_no asc
) as t
where deposit_qty >=1 and withdrawal_qty >=1
	) as t2
group by t2.month_no
order by t2.month_no


-----------------------------------------------------------------------------------
6. What is closing balance for each customer?

select customer_id, t.closing_balance
from (
select 
	customer_id,
	sum(case when txn_type = 'deposit' then txn_amount else 0 end) as total_deposit,
	sum(case when txn_type = 'withdrawal' then txn_amount else 0 end) as total_withdrawal,
		sum(case when txn_type = 'deposit' then txn_amount else 0 end)
			- sum(case when txn_type = 'withdrawal' then txn_amount else 0 end) as closing_balance
from customer_transactions
group by customer_id
order by closing_balance desc
) as t

-----------------------------------------------------------------------------------
7. What is the closing balance for each customer at the end of the month?

select customer_id, months, closing_balance
from 
(
select *,

dense_rank () over( partition by customer_id order by months  asc) as month_name
from 
(
select 
	customer_id,
	month(txn_date) as months,
		sum(case when txn_type = 'deposit' then txn_amount else 0 end)
			- sum(case when txn_type = 'withdrawal' then txn_amount else 0 end) as closing_balance
from customer_transactions
group by customer_id, months
) as t
	) as t2
	
-----------------------------------------------------------------------------------
 7.1  Negative closing balance customers id

select customer_id, months,balance
from 
(
select *,

dense_rank () over( partition by customer_id order by months  asc) as month_name
from 
(
select 
	customer_id,
	month(txn_date) as months,
		sum(case when txn_type = 'deposit' then txn_amount else 0 end)
			- sum(case when txn_type = 'withdrawal' then txn_amount else 0 end) as balance
from customer_transactions

group by customer_id, months
) as t
	) as t2
where balance <0
	
-----------------------------------------------------------------------------------
8. Please show the latest 5 days total withdraw amount.

select  sum(5_days_amount) total_amout_wd
from
(
	select txn_date,txn_type, sum(txn_amount) as 5_days_amount
	from customer_transactions
	where txn_type = 'withdrawal'
	group by txn_date,txn_type
	order by txn_date desc 
	limit 5
) as t

-----------------------------------------------------------------------------------
8.1 Please show the latest 5 days total deposit amount.

select  sum(5_days_amount) total_amout_dp
from
(
	select txn_date,txn_type, sum(txn_amount) as 5_days_amount
	from customer_transactions
	where txn_type = 'deposit'
	group by txn_date,txn_type
	order by txn_date desc 
	limit 5
) as t

-----------------------------------------------------------------------------------
8.2 :

SELECT 
    'withdrawal' AS txn_type,
    SUM(5_days_amount) AS total_amount
FROM (
    SELECT 
        txn_date,
        txn_type,
        SUM(txn_amount) AS 5_days_amount
    FROM customer_transactions
    WHERE txn_type = 'withdrawal'
    GROUP BY txn_date, txn_type
    ORDER BY txn_date DESC
    LIMIT 5
) AS t

UNION ALL

SELECT 
    'deposit' AS txn_type,
    SUM(5_days_amount) AS total_amount
FROM (
    SELECT 
        txn_date,
        txn_type,
        SUM(txn_amount) AS 5_days_amount
    FROM customer_transactions
    WHERE txn_type = 'deposit'
    GROUP BY txn_date, txn_type
    ORDER BY txn_date DESC
    LIMIT 5
) AS t;


-----------------------------------------------------------------------------------
9. Find out the total deposit amount for every five days consecutive series. You can assume 1 week = 5 days. 
	Please show the result week wise total amount.
	
select week_no,    sum(txn_amount) as amount --  week_days,
from
(
select *,
	dense_rank () over(partition by week_no order by days asc ) as week_days
from 
(
	select *,
	dense_rank () over (order by date(txn_date) asc ) as days,
	dense_rank () over (order by date(txn_date) asc ) / 5 as week_dv_by_5days,
	ceiling (dense_rank () over (order by date(txn_date) asc ) / 5) as week_no
	from customer_transactions
) as t
	 ) as t2
where txn_type = 'deposit'
group by week_no -- , week_days

-----------------------------------------------------------------------------------
9.1 Find out the total withdrawal amount for every five days consecutive series. You can assume 1 week = 5 days. 
	Please show the result week wise total amount.
	
select week_no,    sum(txn_amount) as amount --  week_days,
from
(
select *,
	dense_rank () over(partition by week_no order by days asc ) as week_days
from 
(
	select *,
	dense_rank () over (order by date(txn_date) asc ) as days,
	dense_rank () over (order by date(txn_date) asc ) / 5 as week_dv_by_5days,
	ceiling (dense_rank () over (order by date(txn_date) asc ) / 5) as week_no
	from customer_transactions
) as t
	 ) as t2
where txn_type = 'withdrawal'
group by week_no -- , week_days

-----------------------------------------------------------------------------------
9.2 Daily deposit 
	

select  txn_date ,sum(txn_amount) 
from customer_transactions ct 
where txn_type = 'deposit'
group by txn_date


-----------------------------------------------------------------------------------
9.3 Daily withdrawal
	


select  txn_date ,sum(txn_amount) 
from customer_transactions ct 
where txn_type = 'withdrawal'
group by txn_date

	
	
-----------------------------------------------------------------------------------
10. Plase compare every weeks total deposit amount by the following previous week. 

	Example: Week 1 will be compared with Week 2 [Calculation Week2 - Week 1]-> Next week - previous week
		Week 2 will be compared with Week 3  [Calculation Week3 - Week 2]
		
		
select t4.*, amount-Previuos_week_amount as amount_diffi
from
(
select *,
lag (amount) over () as Previuos_week_amount
from
(
select week_no, sum(txn_amount) as amount 
from
(
select *,
	dense_rank () over(partition by week_no order by days asc ) as week_days
from 
(
	select *,
	dense_rank () over (order by date(txn_date) asc ) as days,
	dense_rank () over (order by date(txn_date) asc ) / 5 as week_dv_by_5days,
	ceiling (dense_rank () over (order by date(txn_date) asc ) / 5) as week_no
	from customer_transactions
) as t
	 ) as t2
where txn_type = 'deposit'
group by week_no
		) as t3
			) as t4

-----------------------------------------------------------------------------------
10. Plase compare every weeks total withdrawal amount by the following previous wweek. 

	Example: Week 1 will be compared with Week 2 [Calculation Week2 - Week 1]-> Next week - previous week
		Week 2 will be compared with Week 3  [Calculation Week3 - Week 2]
		
		
select t4.*, amount-Previuos_week_amount as amount_diffi
from
(
select *,
lag (amount) over () as Previuos_week_amount
from
(
select week_no, sum(txn_amount) as amount 
from
(
select *,
	dense_rank () over(partition by week_no order by days asc ) as week_days
from 
(
	select *,
	dense_rank () over (order by date(txn_date) asc ) as days,
	dense_rank () over (order by date(txn_date) asc ) / 5 as week_dv_by_5days,
	ceiling (dense_rank () over (order by date(txn_date) asc ) / 5) as week_no
	from customer_transactions
) as t
	 ) as t2
where txn_type = 'withdrawal'
group by week_no
		) as t3
			) as t4
			
			
-----------------------------------------------------------------------------------
11. Max single deposit &  Max single withdrawal

select*
from 
(
select *
from customer_transactions ct 
where txn_type ='deposit'
order by txn_amount desc 
limit 1
) as t

union ALL

select*
from 
(
select *
from customer_transactions ct 
where txn_type ='withdrawal'
order by txn_amount desc
limit 1
) as t
---------------------
11.1

select *
from customer_joining_info cji 

select *
from customer_transactions ct 


select ct.customer_id, cji.join_date,  r.region_name,a.name as area_name, ct.txn_date, ct.txn_type, ct.txn_amount
from customer_transactions ct
	inner join customer_joining_info cji 
	on ct.customer_id = cji.customer_id
		inner join area as a
		on a.area_id = cji.area_id 
			inner join region as r
			on r.region_id = cji.region_id 
			

--------------------------
11.2


select*
from 
(
select txn_type, count(txn_type) 
from customer_transactions ct 
where txn_type ='deposit'

) as t

union all

select*
from 
(
select txn_type, count(txn_type) 
from customer_transactions ct 
where txn_type ='withdrawal'

) as t

-----
11.2.1

select*
from 
(
select txn_date, txn_type, count(txn_type) 
from customer_transactions ct 
where txn_type ='deposit'
group by txn_date
) as t

union all

select*
from 
(
select txn_date, txn_type, count(txn_type) 
from customer_transactions ct 
where txn_type ='withdrawal'
group by txn_date
) as t

