USE customer_product_analysis;

CREATE TABLE IF NOT EXISTS customers (
    customer_id CHAR(32) PRIMARY KEY,
    customer_unique_id CHAR(32) NOT NULL,
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS orders (
    order_id CHAR(32) PRIMARY KEY,
    customer_id CHAR(32) NOT NULL,
    order_status VARCHAR(30),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimate_delivery_date DATETIME,
    purchase_year SMALLINT,
    purchase_month TINYINT,
    purchase_year_month CHAR(7),
    purchase_day_of_week VARCHAR(10),
    purchase_hour TINYINT,
    delivery_days INT,
    delivery_delay_days INT,
    is_delayed TINYINT,
    is_complete TINYINT
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS order_items (
    order_id CHAR(32) NOT NULL,
    order_item_id INT NOT NULL,
    product_id CHAR(32) NOT NULL,
    seller_id CHAR(32),
    shipping_limit_date DATETIME,
    price DECIMAL (12, 2),
    freight_value DECIMAL (12, 2),
    PRIMARY KEY (order_id, order_item_id)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS products (
    product_id CHAR(32) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g DECIMAL (10, 2),
    product_length_cm DECIMAL (10, 2),
    product_height_cm DECIMAL (10, 2),
    product_width_cm DECIMAL (10, 2)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS reviews(
    review_key BIGINT AUTO_INCREMENT PRIMARY KEY,
    review_id CHAR(32),
    order_id CHAR(32) NOT NULL,
    review_score TINYINT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME
) ENGINE = InnoDB;

SHOW TABLES;