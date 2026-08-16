-- Final analysis tables for Power BI

-- 1. Set up delivery performance analysis

use customer_product_analysis;

drop table if exists delivery_performance;
create table delivery_performance as
select
	o.order_id,
    c.customer_unique_id,
    c.customer_state,
    c.customer_city,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    oi.order_revenue,

    case
		when o.order_purchase_timestamp is null
        or o.order_delivered_customer_date is null
        then null
        else datediff(
			o.order_delivered_customer_date,
            o.order_purchase_timestamp)
	end as delivery_days,

	case
		when o.order_delivered_customer_date is null
        or o.order_estimated_delivery_date is null
        then null
        else datediff(
			o.order_delivered_customer_date,
            o.order_estimated_delivery_date)
	end as delay_days,
    
    case
		when o.order_delivered_customer_date is null
        or o.order_estimated_delivery_date is null
        then null
        when o.order_delivered_customer_date > o.order_estimated_delivery_date
        then 1
        else 0
	end as is_delayed,
    
    case
		when o.order_delivered_customer_date is null
        or o.order_estimated_delivery_date is null
        then 'Unknown'
        when o.order_delivered_customer_date > o.order_estimated_delivery_date
        then 'Delayed'
        else 'On time or early'
	end as delivery_status,
    
    case
		when o.order_delivered_customer_date is null
        or o.order_estimated_delivery_date is null
        then 'Unknown'
        when datediff(
			o.order_delivered_customer_date, o.order_estimated_delivery_date) <= 0
		then 'On time or early'
        when datediff(
			o.order_delivered_customer_date, o.order_estimated_delivery_date) = 1
		then '1 day late'
        when datediff(
			o.order_delivered_customer_date, o.order_estimated_delivery_date) between 2 and 5
		then '2 to 5 days late'
        when datediff(
			o.order_delivered_customer_date, o.order_estimated_delivery_date) between 6 and 10
		then '6 to 10 days late'
		else 'More than 10 days late'
	end as delay_group,
    
    r.review_score

from orders o
inner join customers c
	on o.customer_id = c.customer_id
inner join (
	select order_id, sum(price) as order_revenue
	from order_items
	group by order_id) oi on o.order_id = oi.order_id
left join (
	select order_id, avg(review_score) as review_score
	from reviews
	group by order_id) r on o.order_id = r.order_id
where o.order_status = 'delivered';

-- 2. Check if delivery_performance has been set up successfully

select
	count(*) as total_rows,
    count(distinct order_id) as distinct_orders
from delivery_performance;

select *
from delivery_performance
limit 10;

-- Set up customer summary

drop table if exists customer_summary;
create table customer_summary as
select
	customer_unique_id,
    count(*) as total_orders,
    round(sum(order_revenue), 2) as total_revenue,
    round(avg(order_revenue), 2) as avg_order_value,
    min(order_purchase_timestamp) as first_order_date,
    max(order_purchase_timestamp) as last_order_date,
    case
		when count(*) > 1
        then 1
        else 0
	end as is_repeat_customer,
    
    case
		when count(*) > 1
        then 'Repeat customer'
        else 'One-time customer'
	end as customer_type

from delivery_performance
group by customer_unique_id;

-- 3. Check if customer_summary has been set up successfully

select
	count(*) as total_rows,
    count(distinct customer_unique_id) as distinct_customers
from customer_summary;

select *
from customer_summary
order by total_revenue DESC
limit 10;

select
	customer_type,
    count(*) as total_customers,
    round(count(*) * 100.0 / (select count(*) from customer_summary), 2) as customer_pct
from customer_summary
group by customer_type;

-- 4. Check if product performance can be accessed successfully

select *
from product_performance
limit 10;

select
	count(*) as total_rows
from product_performance;

select
	round(sum(order_revenue), 2) as final_order_revenue
from delivery_performance;

select
	round(sum(revenue), 2) as product_table_revenue
from product_performance;

-- 5. Set up regional performance

drop table if exists regional_performance;
create table regional_performance as
select
	s.customer_state,
    s.total_orders,
    s.total_customers,
    s.total_revenue,
    s.avg_order_value,
    s.revenue_per_customer,
    s.avg_review_score,
    s.delayed_order_rate_pct,
    r.repeat_customers,
    r.repeat_purchase_rate_pct
from (select
		customer_state,
        count(*) as total_orders,
        count(distinct customer_unique_id) as total_customers,
        round(sum(order_revenue), 2) as total_revenue,
        round(avg(order_revenue), 2) as avg_order_value,
        round(sum(order_revenue) / count(distinct customer_unique_id), 2) as revenue_per_customer,
        round(avg(review_score), 2) as avg_review_score,
        round(avg(is_delayed) * 100, 2) as delayed_order_rate_pct
	from delivery_performance
    group by customer_state) s
left join (
	select
		customer_state,
        count(*) as total_customers,
        sum(case
				when customer_order_count > 1
                then 1
                else 0
			end) as repeat_customers,
		round(sum(
			case
				when customer_order_count > 1
				then 1
				else 0
			end) * 100.0 / count(*), 2) as repeat_purchase_rate_pct
	from (select
			customer_state,
            customer_unique_id,
            count(*) as customer_order_count
		from delivery_performance
        group by
			customer_state,
            customer_unique_id) customer_order_by_state
	group by customer_state) r on s.customer_state = r.customer_state;

-- 6. Check if regional performance has been set up successfully

select *
from regional_performance
order by total_revenue DESC;

select
	sum(total_orders) as regional_total_orders,
    round(sum(total_revenue), 2) as regional_total_revenue
from regional_performance;

select
	count(*) as final_total_orders,
    round(sum(order_revenue), 2) as final_total_revenue
from delivery_performance;

-- 7. Revenue validation

select
	round(sum(oi.price), 2) as raw_delivered_revenue
from orders o
inner join order_items oi
	on o.order_id = oi.order_id
where order_status = 'delivered';

select
	round(sum(order_revenue), 2) as final_table_revenue
from delivery_performance;

-- 8. Order count validation

select
	count(distinct o.order_id) as raw_delivered_orders
from orders o
inner join order_items oi
	on o.order_id = oi.order_id
where order_status = 'delivered';

select
	count(*) as final_orders
from delivery_performance;

-- 9. Customer count validation

select
	count(distinct customer_unique_id) as raw_unique_customers
from orders o
inner join customers c
	on o.customer_id = c.customer_id
inner join order_items oi
	on o.order_id = oi.order_id
where o.order_status = 'delivered';

select
	count(*) as final_unique_customers
from customer_summary;

-- 10. Select 10 orders and manually verify Revenue

select
	d.order_id,
    d.order_revenue as final_revenue,
    round(sum(oi.price), 2) as recalculated_revenue,
    round(d.order_revenue - sum(oi.price), 2) as difference
from delivery_performance d
inner join order_items oi
	on d.order_id = oi.order_id
group by
	d.order_id,
    d.order_revenue
order by d.order_id
limit 10;

-- 11. Select 10 orders and verify Delivery and Review

select
	d.order_id,
    d.delivery_days,
    datediff(
		o.order_delivered_customer_date,
        o.order_purchase_timestamp) as recalculated_delivery_days,

	d.delay_days,
	datediff(
		o.order_delivered_customer_date,
        o.order_estimated_delivery_date) as recalculated_delay_days,

    round(d.review_score, 2) as final_review_score,
    round(avg(r.review_score), 2) as recalculated_review_score

from delivery_performance d
inner join orders o
	on d.order_id = o.order_id
left join reviews r
	on d.order_id = r.order_id
where d.order_delivered_customer_date is not null
  and d.order_estimated_delivery_date is not null
group by
	d.order_id,
    d.delivery_days,
    o.order_delivered_customer_date,
    o.order_purchase_timestamp,
    d.delay_days,
    o.order_estimated_delivery_date,
    d.review_score
order by d.order_id
limit 10;

-- 12. Final check the tables for Power BI

show tables;
select count(*) from product_performance;
select count(*) from customer_summary;
select count(*) from delivery_performance;
select count(*) from regional_performance;

-- 13. Summary:
-- The final analysis layer was prepared for Power BI by structuring the data into four main levels: order, customer, product, and region.
-- The delivery_performance table was created at order level, capturing revenue, delivery time, delay, and review information for each delivered order.
-- The customer_summary table aggregates customer behaviour, including total orders, revenue, and repeat purchase status.
-- Regional performance was summarised at state level, while product_performance was kept as a product category view.
-- Validation checks were performed to ensure data consistency across all tables.
-- Order counts, customer counts, and total revenue were matched against the original transaction data to avoid duplication issues.
-- Final delivered order revenue was confirmed as 13,221,498.11, and sample-level checks verified that delivery time, delay, and review metrics were correctly calculated.

-- 14. Business insight:
-- This structured data model ensures a reliable foundation for Power BI analysis by separating different levels of granularity.
-- It prevents double counting issues caused by multi-product orders and repeated reviews, and enables consistent comparison across product, customer, delivery, and regional performance using standardised metrics.