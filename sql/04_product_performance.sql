-- Product performance analysis

-- Revenue by product category

-- Orders by product category

-- Average product price and average order value

-- Top and bottom performing categories

use customer_product_analysis;

create or replace view customer_product_analysis.product_performance as
select coalesce(nullif(trim(p.product_category), ''), 'unknown') as product_category,
    
    count(distinct oi.order_id) as number_of_orders,
    
    count(*) as units_sold,
    
    count(distinct oi.product_id) as unique_products_sold,
    
    round(sum(oi.price), 2) as revenue,
    
    round(avg(oi.price), 2) as average_product_price,
    
    round(sum(oi.price) / nullif(count(distinct oi.order_id), 0), 2) as average_order_value,
    
    round(sum(oi.freight_value), 2) as total_freight_price,
    
    round(sum(oi.price + oi.freight_value), 2) as gross_order_value

from customer_product_analysis.order_items as oi

inner join customer_product_analysis.orders as o
	on oi.order_id = o.order_id
    
inner join customer_product_analysis.products as p
	on oi.product_id = p.product_id

where o.order_status = 'delivered'

group by coalesce(nullif(trim(p.product_category), ''), 'unknown');


-- Check if the view is created successfully

show full tables
from customer_product_analysis
where table_type = 'VIEW';

select *
from customer_product_analysis.product_performance
limit 20;

-- Check which product category has the highest revenue

select
	product_category,
    revenue,
    number_of_orders,
    units_sold,
    average_product_price,
    average_order_value
from product_performance
order by revenue DESC
limit 10;

-- Check which product category has the highest number of orders

select
	product_category,
    number_of_orders,
    units_sold,
    revenue,
    average_order_value
from product_performance
order by number_of_orders DESC
limit 10;

-- Check which product categroy has the highest units sold

select
	product_category,
    units_sold,
    number_of_orders,
    revenue,
    average_product_price
from product_performance
order by units_sold DESC
limit 10;

-- Check which product category has the lowest revenue

select
	product_category,
    revenue,
    number_of_orders,
    units_sold,
    average_product_price
from product_performance
where product_category <> 'Unknown'
order by revenue ASC
limit 10;

-- Compare the revenue with the volumn

with product_rankings as (
	select
		product_category,
        revenue,
        number_of_orders,
        units_sold,
        average_product_price,
        average_order_value,
        
        DENSE_RANK () over (order by revenue DESC) as revenue_rank,
        
        DENSE_RANK () over (order by units_sold DESC) as volumn_rank
        
        from product_performance
        
        where product_category <> 'Unknown')

select
	product_category,
    revenue,
    units_sold,
    average_product_price,
    average_order_value,
    revenue_rank,
    volumn_rank,
    
    case
		when revenue_rank <= 10
			and volumn_rank <= 10
            then 'High revenue, high volumn'
            
		when revenue_rank <= 10
			and volumn_rank > 10
            then 'High revenue, low volumn'
            
		when revenue_rank > 10
			and volumn_rank <= 10
            then 'Low revenue, high volumn'
		
        else 'Other'
	end as performance_pattern

from product_rankings

where revenue_rank <= 10
	or volumn_rank <= 10

order by revenue_rank, volumn_rank;