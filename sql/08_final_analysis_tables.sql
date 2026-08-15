-- Final analysis tables for Power BI

-- Set up delivery performance analysis

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

-- Check if delivery_performance has been set up successfully

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

-- Check if customer_summary has been set up successfully

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

-- Check if product performance can be accessed successfully

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

-- Set up regional performance

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

-- Check if regional performance has been set up successfully

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