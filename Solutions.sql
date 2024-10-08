-- Monday Coffee -- Data Analysis 

select * from city;
select * from customers;
select * from products;
select * from sales;

-- Reports & Data Analysis

-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

select city_name, 
       ROUND((population * 0.25) / 1000000, 2) as coffee_consumers_in_million,
	   city_rank
from city
order by 2 desc;

-- OR --

select city_name, 
       (population + population * 25/100) - population as population_consume_coffee,
	   city_rank
from city
order by 2 desc;


-- Q.2 Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

select 
	ct.city_name,
	sum(s.total) as total_revenue
from sales as s
join customers as c on c.customer_id = s.customer_id
join city as ct on ct.city_id = c.city_id
where 
	extract(year from s.sale_date) = 2023 and extract(quarter from s.sale_date) = 4
group by ct.city_name
order by 2 desc;


-- Q.3 Sales Count for Each Product
-- How many units of each coffee product have been sold?

select 
	p.product_id, p.product_name, 
	count(s.sale_id) as total_units_sold 
from products as p
join sales as s on p.product_id = s.product_id
group by p.product_id, p.product_name
order by 3 desc ;


-- Q.4 Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- 1. city and total sale
-- 2. no. of distinct customers in each city
-- 3. average sales amount per customer

select 
	ct.city_name,
	sum(s.total) as total_revenue,
	count(distinct c.customer_id) as total_customers,
	ROUND(
		sum(s.total)::numeric / count(distinct c.customer_id)::numeric, 2) as avg_sale_per_customer
from sales as s
join customers as c on c.customer_id = s.customer_id
join city as ct on ct.city_id = c.city_id
group by ct.city_name
order by 2 desc;


-- Q.5 City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

with city_table as (
select 
	city_name, 
	population,
	round((population * 0.25) / 1000000, 2) as estimated_coffee_consumers_in_millions
from city
),

customer_table as (
select 
	ct.city_name,
    count(distinct c.customer_id) as unique_customer
from city as ct
join customers as c on c.city_id = ct.city_id
join sales as s on s.customer_id = c.customer_id
group by ct.city_name
)

select 
	city_table.city_name,
	city_table.estimated_coffee_consumers_in_millions,
	customer_table.unique_customer
from city_table
join customer_table on customer_table.city_name = city_table.city_name;


-- Q6 Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

with product_ranking_table as (
	select 
		p.product_name,
		ct.city_name,
		count(s.sale_id) as sales_volume,
		dense_rank() over(partition by ct.city_name order by count(s.sale_id) desc) as ranking
	from sales as s
	join customers as c on s.customer_id = c.customer_id 
	join products as p on p.product_id = s.product_id 
	join city as ct on ct.city_id = c.city_id
	group by 1, 2
	)

select city_name, product_name, sales_volume
from product_ranking_table
where ranking <= 3;


-- Q.7 Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT 
	ct.city_name,
	count(distinct c.customer_id) as unique_customers
FROM city as ct
JOIN customers as c on c.city_id = ct.city_id
join sales as s on s.customer_id = c.customer_id
where s.product_id IN (select distinct product_id from products)
group by 1
order by 2 desc;


-- Q.8 Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer.

select 
	ct.city_name,
	round(
		sum(s.total)::numeric / count(distinct c.customer_id)::numeric, 2) as avg_sale_per_customer,
	round(
		ct.estimated_rent::numeric / count(distinct c.customer_id)::numeric, 2) as avg_rent_per_customer
from city as ct
join customers as c on c.city_id = ct.city_id
join sales as s on s.customer_id = c.customer_id
group by ct.city_name, ct.estimated_rent
order by 2 desc;


-- Q.9 Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different 
-- time periods (monthly) by each city

with monthly_sales as 
(
	SELECT 
		ct.city_name,
		extract(month from sale_date) as month,
		extract(year from sale_date) as year,
		sum(s.total) as total
	FROM sales as s
	JOIN customers as c on c.customer_id = s.customer_id
	join city as ct on ct.city_id = c.city_id
	group by 1, 2, 3
	order by 1, 3, 2
),

curr_last_month_sales as
(
	select 
		city_name,
		month,
		year,
		total as current_month_sales,
		lag(total, 1) over(partition by city_name order by year, month) as last_month_sales
	from monthly_sales
)

select 
	city_name, month, year, current_month_sales, last_month_sales,
	current_month_sales - coalesce(last_month_sales, 0) as growth,
	round((current_month_sales - last_month_sales)::numeric / last_month_sales::numeric * 100, 2)  as growth_ratio
from curr_last_month_sales
where last_month_sales is not null;


-- Q.10 Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, 
-- total customers, estimated coffee consumer

SELECT 
	ct.city_name,
	sum(s.total) as total_sales,
	ct.estimated_rent as total_rent,
	count(distinct c.customer_id) as customer_count,
	round((population * 0.25) / 1000000, 2) as estimated_coffee_consumers_in_millions,
	round(
		sum(s.total)::numeric / count(distinct c.customer_id)::numeric, 2) as avg_sale_per_customer,
	round(
		ct.estimated_rent::numeric / count(distinct c.customer_id)::numeric, 2) as avg_rent_per_customer
FROM sales as s
JOIN customers as c on c.customer_id = s.customer_id
join city as ct on ct.city_id = c.city_id
group by 1, 3, 5
order by 2 desc


-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.



