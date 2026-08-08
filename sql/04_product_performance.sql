-- 1. Use database and create view product_performance

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

-- 2. Check if the view is created successfully

show full tables
from customer_product_analysis
where table_type = 'VIEW';

select *
from customer_product_analysis.product_performance
limit 20;

-- 3. Check which product category has the highest revenue (top 10 categroies)

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

-- 4. Check which product category has the highest number of orders (top 10 categories)

select
	product_category,
    number_of_orders,
    units_sold,
    revenue,
    average_order_value
from product_performance
order by number_of_orders DESC
limit 10;

-- 5. Check which product categroy has the highest units sold (top 10 categories)

select
	product_category,
    units_sold,
    number_of_orders,
    revenue,
    average_product_price
from product_performance
order by units_sold DESC
limit 10;

-- 6. Check which product category has the lowest revenue (bottom 10 categories)

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

-- 7. Compare the revenue with the volumn

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

-- 8. Check if the revenue and the sales figures have been double-counted

select
	count(*) as delivered_units,
    round(sum(oi.price), 2) as delivered_revenue
from order_items as oi
inner join orders as o
	on oi.order_id = o.order_id
where o.order_status = 'delivered';

select
	sum(units_sold) as view_units,
    round(sum(revenue), 2) as view_revenue
from product_performance;

-- 9. Check the unknown category

select *
from product_performance
where product_category = 'Unknown';

select
	pp.number_of_orders as unknown_orders,
    pp.units_sold as unknown_units,
    pp.revenue as unknown_revenue,

	round(pp.units_sold / totals.total_units * 100, 2) as unknown_units_pct,
    round(pp.revenue / totals.total_revenue * 100, 2) as unknown_revenue_pct,
    round(pp.number_of_orders / delivered.total_delivered_orders * 100, 2) as unknown_orders_pct

from product_performance as pp

cross join(
	select sum(units_sold) as total_units, sum(revenue) as total_revenue
	from product_performance) as totals

cross join(
	select count(distinct oi.order_id) as total_delivered_orders
    from order_items as oi
    inner join orders as o
		on oi.order_id = o.order_id
	where o.order_status = 'delivered') as delivered

where pp.product_category = 'Unknown';

-- 10. Product performance findings summary

-- Finding 1:
-- The product category with the highest revenue was health_beauty, gathering 1,233,131.72 from 8,647 delivered orders.

-- Finding 2:
-- Garden_tools and telephony ranked highly in sales volumn but had a lower revenue ranking, which may be explained by their low average product prices.

-- Finding 3:
-- Cool_stuff and toys generated a high revenue despite a lower sales volumn, which suggesting that their performance were driven by their higher-priced products.

-- Finding 4:
-- Approximately 1.4% of sold units and 1.3% of revenue were associated with products without a valid category.
-- These records were retained and labelled as Unknown to avoid removing valid transaction data.