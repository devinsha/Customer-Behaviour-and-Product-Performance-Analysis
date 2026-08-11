-- Delivery and review analysis

-- Set up VIEW

drop view if exists vw_delivery_review_order;
create view vw_delivery_review_order as

select
	o.order_id,
    o.customer_id,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    datediff(
		o.order_delivered_customer_date,
        o.order_purchase_timestamp) as delivery_days,
	datediff(
		o.order_delivered_customer_date,
        o.order_estimated_delivery_date) as delay_days,
	case
		when o.order_delivered_customer_date > o.order_estimated_delivery_date
        then 1
        else 0
	end as is_delayed,
    
    r.review_score

from orders o
left join (
	select
		order_id, avg(review_score) as review_score
	from reviews
    group by order_id) r on o.order_id = r.order_id

where o.order_status = 'delivered'
	and o.order_purchase_timestamp is not null
    and o.order_delivered_customer_date is not null
    and o.order_estimated_delivery_date is not null;

-- Check if there is any duplicate orders

select
	count(*) as total_rows,
    count(distinct order_id) as distinct_orders
from vw_delivery_review_order;

-- Check missing reviews

select
	count(*) as total_orders,
    sum(case
			when review_score is null then 1
            else 0
		end) as orders_without_review
from vw_delivery_review_order;

-- Calculate key delivery and review analysis KPIs

select
	count(*) as total_delivered_orders,
    round(avg(delivery_days), 2) as avg_delivery_days,
    round(avg(is_delayed) * 100, 2) as delayed_order_rate_pct,
    round(avg(review_score), 2) as avg_review_score,
    round(avg(
			case
				when is_delayed = 0
                then review_score
			end), 2) as on_time_avg_review_socre,
	round(avg(
			case
				when is_delayed = 1
                then review_score
			end), 2) as delayed_avg_review_score
from vw_delivery_review_order;

-- On time orders and delayed orders comparison

select
	case
		when is_delayed = 0 then 'On time'
        when is_delayed = 1 then 'Delayed'
	end as delivery_status,
    count(*) as total_orders,
    round(count(*) * 100 / (select
								count(*)
							from vw_delivery_review_order), 2) as order_pct,
	round(avg(delivery_days), 2) as avg_delivered_days,
    round(avg(review_score), 2) as avg_review_score
from vw_delivery_review_order
group by is_delayed
order by is_delayed;

-- Analyse the extent of delayes

select
	case
		when delay_days <= 0
			then 'On time or early'
        when delay_days = 1
			then '1 day late'
		when delay_days between 2 and 5
			then '2 to 5 days late'
		when delay_days between 6 and 10
			then '6 to 10 days late'
		else 'More than 10 days late'
	end as delay_group,
    
    count(*) as total_orders,
    round(avg(delay_days), 2) as avg_delay_days,
    round(avg(review_score), 2) as avg_review_score

from vw_delivery_review_order
group by delay_group
order by
	case delay_group
		when 'On time or early' then 1
        when '1 day late' then 2
        when '2 to 5 days late' then 3
        when '6 to 10 days late' then 4
        when 'More than 10 days late' then 5
	end;

-- Delivery and review analysis summary:

-- A total of 96,470 delivered orders were analysed.
-- Most orders have been delivered on time or earlier than estimated date.
-- While 7,826 orders were delayed, representing approximately 8.11% of delivered orders.

-- Customer review scores show a clear negative relationship with delivery delays.
-- Orders delivered on time or early received an average score of 4.29.
-- The average score fell to 3.73 for orders delayed by 1 day, 2.67 for delays of 2 to 5 days, 1.77 for delays of 6 to 10 days, and 1.71 for delays more than 10 days.
-- This suggests that longer delivery delays are strongly associated with low customer satisfcation.
-- Therefore, delivery performance should be monitored, particularly for orders with delays exceeding 5 days, as these orders received lower review scores.

-- Business insight:
-- Improving delivery reliability and identifying orders at risk of significant delays could help improve customer satisfaction and reduce low review scores.