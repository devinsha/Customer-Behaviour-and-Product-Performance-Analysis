-- Regional analysis

-- Set up regional view for orders

drop view if exists vw_regional_order_analysis;
create view vw_regional_order_analysis as
select
	o.order_id,
    c.customer_unique_id,
    c.customer_state,
    c.customer_city,
    oi.order_revenue,
    r.review_score,
    case
		when o.order_delivered_customer_date is null
			or o.order_estimated_delivery_date is null
        then null
        when o.order_delivered_customer_date > o.order_estimated_delivery_date
        then 1
        else 0
	end as is_delayed
from orders o
inner join customers c
	on o.customer_id = c.customer_id

inner join (
	select
		order_id,
		sum(price) as order_revenue
	from order_items
	group by order_id) oi on o.order_id = oi.order_id

left join (
	select
		order_id,
		avg(review_score) as review_score
	from reviews
	group by order_id) r on o.order_id = r.order_id

where o.order_status = 'delivered';

-- Check if there is any duplicate orders

select
	count(*) as total_rows,
    count(distinct order_id) as distinct_orders
from vw_regional_order_analysis;

-- State level regional performance

select
	customer_state,
    count(*) as total_orders,
    count(distinct customer_unique_id) as total_customers,
    round(sum(order_revenue), 2) as total_revenue,
    round(avg(order_revenue), 2) as avg_order_revenue,
    round(sum(order_revenue) / count(distinct customer_unique_id), 2) as revenue_per_customer,
    round(avg(review_score), 2) as avg_review_score,
    round(avg(is_delayed) * 100, 2) as delayed_order_rate_pct
from vw_regional_order_analysis
group by customer_state
order by total_revenue DESC;

-- Calculate the repeat purchase rate for each state

with customer_orders_by_state as (
	select
		customer_state,
        customer_unique_id,
        count(*) as customer_order_count
	from vw_regional_order_analysis
    group by
		customer_state,
        customer_unique_id)
select customer_state,
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
from customer_orders_by_state
group by customer_state
order by repeat_purchase_rate_pct DESC;

-- City level regional performance

select
	customer_state, customer_city,
    count(*) as total_orders,
    count(distinct customer_unique_id) as total_customers,
    round(sum(order_revenue), 2) as total_revenue,
    round(avg(order_revenue), 2) as avg_order_value,
    round(sum(order_revenue) / count(distinct customer_unique_id), 2) as revenue_per_customer,
    round(avg(review_score), 2) as avg_review_score,
    round(avg(is_delayed) * 100, 2) as delayed_order_rate_pct
from vw_regional_order_analysis
group by
	customer_state, customer_city
having count(*) >= 50
order by total_revenue DESC
limit 20;

-- Regional analysis summary:

-- Regional performance varies substantially across Brazilian states. São Paulo was by far the largest market, generating approximately 5.07 million in revenue from 40,501 delivered orders and 39,156 customers.
-- Rio de Janeiro and Minas Gerais were the next largest markets, generating approximately 1.76 million and 1.55 million in revenue respectively.

-- Total revenue alone does not fully represent customer value. Some smaller markets recorded higher average order values and revenue per customer.
-- For example, Paraíba generated an average order value of 217.77 and revenue per customer of 223.39, considerably higher than São Paulo at 125.12 and 129.42 respectively.
-- However, these smaller markets have much lower customer volumes, so their results should be interpreted with caution.

-- Customer experience also differs across regions. São Paulo recorded a relatively strong average review score of 4.25 and a delayed order rate of 5.89%.
-- In comparison, Rio de Janeiro had a lower average review score of 3.97 and a much higher delayed order rate of 13.47%.
-- Bahia showed a similar pattern, with an average review score of 3.93 and a delayed order rate of 14.04%.
-- Maranhão had one of the highest delayed order rates among the displayed states at 19.67%, together with a relatively low average review score of 3.83.

-- Repeat purchase rates were generally low across states. Acre recorded the highest observed repeat purchase rate at 5.26%, but this was based on only 76 customers and should not be treated as representative of larger markets.
-- Among the major states, Rio de Janeiro had a repeat purchase rate of 3.25%, São Paulo 3.10%, Rio Grande do Sul 3.04%, and Minas Gerais 2.89%.

-- At city level, São Paulo was the largest market, generating approximately 1.86 million in revenue from 15,045 orders. Rio de Janeiro followed with approximately 955,574 in revenue.
-- Delivery performance varied considerably between major cities.
-- Curitiba recorded a relatively low delayed order rate of 4.97% and an average review score of 4.26, while Salvador and Fortaleza recorded much higher delayed order rates of 17.51% and 17.96%, together with lower average review scores of 3.80 and 3.92.

-- Regional analysis business insight:

-- The analysis suggests that regional performance should be evaluated using a combination of market size, customer value, repeat purchasing and delivery experience.
-- São Paulo remains the most important market because of its scale and relatively strong customer experience.
-- Smaller regions with high revenue per customer may provide opportunities for higher-value customer targeting, although their smaller sample sizes need to be considered.
-- Regions such as Rio de Janeiro, Bahia, Maranhão, Salvador and Fortaleza show comparatively high delivery delay rates and lower customer ratings, making logistics performance in these areas a potential priority for improvement.
-- Repeat purchase rates are low across most regions, which suggesting that customer retention may also represent an opportunity for further investigation.