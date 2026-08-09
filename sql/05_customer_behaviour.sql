-- 1. Customer Behaviour Summary

create or replace view customer_behaviour_summary as

select
	customer_stats.customer_unique_id,
    customer_stats.order_count,
    customer_stats.total_revenue,
    customer_stats.total_revenue / customer_stats.order_count as avg_order_value,
    case
		when customer_stats.order_count = 1 then 'One-time'
        when customer_stats.order_count > 1 then 'Repeat'
	end as customer_type,
    latest_location.customer_state

from (
	select
		c.customer_unique_id,
        count(distinct o.order_id) as order_count,
        sum(ov.order_value) as total_revenue
    from customers c
    join orders o on c.customer_id = o.customer_id
    join (
		select order_id, sum(price + freight_value) as order_value
        from order_items
        group by order_id) ov on o.order_id = ov.order_id
	where o.order_status = 'delivered'
    group by c.customer_unique_id) customer_stats

left join (
	select customer_unique_id, customer_state
    from (
		select c.customer_unique_id, c.customer_state,
			row_number() over (
				partition by c.customer_unique_id
                order by o.order_purchase_timestamp DESC, o.order_id DESC) as rn
		from customers c
        join orders o on c.customer_id = o.customer_id
        where o.order_status = 'delivered') ranked_locations
	where rn = 1)

latest_location
	on customer_stats.customer_unique_id = latest_location.customer_unique_id;

-- 2. Check if the VIEW has been created successfully

select *
from customer_behaviour_summary
limit 20;

select
	count(*) as total_rows,
    count(distinct customer_unique_id) as unique_customer_ids
from customer_behaviour_summary;

select customer_unique_id, count(*) as row_count
from customer_behaviour_summary
group by customer_unique_id
having count(*) > 1;

-- 3. Calculate key customer KPIs

select
	count(*) as unique_customers,

    sum(case
			when order_count = 1 then 1
            else 0
		end) as one_time_customers,

	sum(case
			when order_count > 1 then 1
            else 0
		end) as repeat_customers,

	round(100 *
		sum(case
				when order_count > 1 then 1
                else 0
			end) / count(*), 2) as repeat_purchase_rate_pct,

	round(avg(order_count), 2) as avg_orders_per_customer,

    round(avg(total_revenue), 2) as avg_revenue_per_customer

from customer_behaviour_summary;

-- 4. One-time customer and repeat customer comparison

select customer_type,
	count(*) as customer_count,
	round(avg(order_count), 2) as avg_orders_per_customer,
    round(avg(total_revenue), 2) as avg_revenue_per_customer,
    round(avg(avg_order_value), 2) as avg_order_value
from customer_behaviour_summary
group by customer_type
order by avg_revenue_per_customer DESC;

-- 5. Repeat customer purchase frequency

select
	count(*) as repeat_customers,
    round(avg(order_count), 2) as avg_order_per_repeat_customer,
    min(order_count) as min_orders,
    max(order_count) as max_orders
from customer_behaviour_summary
where order_count > 1;

-- 6. Repeat purchase rate in different region

select customer_state,
	count(*) as unique_customers,
    sum(case
			when order_count > 1 then 1
            else 0
		end) as repeat_customers,
	round(100 *
			sum(case
					when order_count > 1 then 1
                    else 0
				end) / count(*), 2) as repeat_purchase_rate_pct,
	round(avg(total_revenue), 2) as avg_revenue_per_customer
from customer_behaviour_summary
where customer_state is not null
group by customer_state
order by repeat_purchase_rate_pct DESC;

-- 7. Top repeat customers

select
	customer_unique_id,
    order_count,
    round(total_revenue, 2) as total_revenue,
    round(avg_order_value, 2) as avg_order_value,
    customer_state
from customer_behaviour_summary
where order_count > 1
order by total_revenue DESC
limit 20;

-- 8. Final data check

select
	count(*) as total_rows,
    count(distinct customer_unique_id) as unique_customer_ids
from customer_behaviour_summary;

select
	customer_unique_id,
    count(*) as total_rows
from customer_behaviour_summary
group by customer_unique_id
having count(*) > 1;