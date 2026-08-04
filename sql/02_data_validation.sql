-- Data validation queries

-- Check row counts for each table

-- Check order status distribution

-- Check missing values and duplicate keys

USE customer_product_analysis;

select "customers" as table_name, count(*) as row_count
from customers

union all

select "orders", count(*)
from orders

union all

select "order_items", count(*)
from order_items

union all

select "products", count(*)
from products

union all

select "reviews", count(*)
from reviews;