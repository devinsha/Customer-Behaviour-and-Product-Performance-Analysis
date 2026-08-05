use customer_product_analysis;

# Restore ID column types after pandas to_sql replacement
ALTER Table orders
modify order_id CHAR(32) not null,
modify customer_id CHAR(32) not null;

ALTER Table products modify product_id CHAR(32) not null;

# Add primary keys
ALTER TABLE orders ADD PRIMARY KEY (order_id);

ALTER TABLE products ADD PRIMARY KEY (product_id);

# Add foreign keys
alter table orders
add constraint fk_orders_customer Foreign Key (customer_id) REFERENCES customers (customer_id);

alter table order_items
add constraint fk_order_items_order Foreign Key (order_id) REFERENCES orders (order_id);

alter table order_items
add constraint fk_order_items_product Foreign Key (product_id) REFERENCES products (product_id);

alter table reviews
add constraint fk_reviews_order Foreign Key (order_id) REFERENCES orders (order_id);

# Add indexes
CREATE INDEX idx_customers_unique_id ON customers(customer_unique_id);

CREATE INDEX idx_orders_purchase_timestamp ON orders (order_purchase_timestamp);

CREATE INDEX idx_orders_status ON orders (order_status);

CREATE INDEX idx_products_category ON products (product_category);

CREATE INDEX idx_reviews_score ON reviews (review_score);