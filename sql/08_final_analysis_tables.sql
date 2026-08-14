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