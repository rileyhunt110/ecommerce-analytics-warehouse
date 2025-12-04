-- =========================================
-- 01_schema.sql
-- E-commerce Analytics Warehouse (PostgreSQL)
-- =========================================

-- Safety first: drop tables in dependency order (for dev/rebuilds)
DROP TABLE IF EXISTS fact_order_item CASCADE;
DROP TABLE IF EXISTS fact_order CASCADE;
DROP TABLE IF EXISTS dim_channel CASCADE;
DROP TABLE IF EXISTS dim_date CASCADE;
DROP TABLE IF EXISTS dim_product CASCADE;
DROP TABLE IF EXISTS dim_customer CASCADE;

-- ===========================
-- Dimension: Customer
-- ===========================
CREATE TABLE dim_customer (
    customer_id         BIGSERIAL PRIMARY KEY,
    customer_key        VARCHAR(50) UNIQUE NOT NULL, -- natural key from source system (or synthetic)
    first_name          VARCHAR(100),
    last_name           VARCHAR(100),
    email               VARCHAR(255),
    phone               VARCHAR(50),
    created_date        DATE,                        -- sign-up date
    country             VARCHAR(100),
    region              VARCHAR(100),                -- e.g. state/province
    city                VARCHAR(100),
    postal_code         VARCHAR(20),
    segment             VARCHAR(50)                  -- e.g. 'Retail', 'Wholesale', 'VIP'
);

CREATE INDEX idx_dim_customer_email ON dim_customer(email);


-- ===========================
-- Dimension: Product
-- ===========================
CREATE TABLE dim_product (
    product_id          BIGSERIAL PRIMARY KEY,
    product_sku         VARCHAR(50) UNIQUE NOT NULL,
    product_name        VARCHAR(255) NOT NULL,
    brand               VARCHAR(100),
    category            VARCHAR(100),
    subcategory         VARCHAR(100),
    list_price          NUMERIC(10,2),
    cost                NUMERIC(10,2),
    is_active           BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_dim_product_category ON dim_product(category);
CREATE INDEX idx_dim_product_brand ON dim_product(brand);


-- ===========================
-- Dimension: Date
-- (Standard date dimension for analytics)
-- ===========================
CREATE TABLE dim_date (
    date_id             INTEGER PRIMARY KEY,  -- yyyymmdd (e.g., 20250131)
    date_actual         DATE NOT NULL,
    year                INTEGER NOT NULL,
    quarter             INTEGER NOT NULL,     -- 1-4
    month               INTEGER NOT NULL,     -- 1-12
    day                 INTEGER NOT NULL,     -- 1-31
    day_of_week         INTEGER NOT NULL,     -- 1=Mon .. 7=Sun
    is_weekend          BOOLEAN NOT NULL,
    week_of_year        INTEGER NOT NULL
);

CREATE UNIQUE INDEX idx_dim_date_actual ON dim_date(date_actual);


-- ===========================
-- Dimension: Channel
-- (How the customer got to us)
-- ===========================
CREATE TABLE dim_channel (
    channel_id          BIGSERIAL PRIMARY KEY,
    channel_name        VARCHAR(100) NOT NULL,  -- e.g. 'Direct', 'Email', 'Paid Search'
    channel_group       VARCHAR(100),          -- e.g. 'Organic', 'Paid', 'Owned'
    details             VARCHAR(255)           -- e.g. default campaign notes
);

CREATE UNIQUE INDEX idx_dim_channel_name ON dim_channel(channel_name);


-- ===========================
-- Fact: Order
-- One row per order
-- ===========================
CREATE TABLE fact_order (
    order_id            BIGSERIAL PRIMARY KEY,
    order_number        VARCHAR(50) UNIQUE NOT NULL,   -- from source (or synthetic)
    customer_id         BIGINT NOT NULL REFERENCES dim_customer(customer_id),
    order_date_id       INTEGER NOT NULL REFERENCES dim_date(date_id),
    channel_id          BIGINT REFERENCES dim_channel(channel_id),
    order_status        VARCHAR(50) NOT NULL,          -- 'Completed', 'Cancelled', 'Refunded', etc.
    order_subtotal      NUMERIC(12,2) NOT NULL DEFAULT 0,
    order_tax           NUMERIC(12,2) NOT NULL DEFAULT 0,
    order_shipping      NUMERIC(12,2) NOT NULL DEFAULT 0,
    order_discount      NUMERIC(12,2) NOT NULL DEFAULT 0,
    order_total         NUMERIC(12,2) NOT NULL DEFAULT 0,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_fact_order_customer ON fact_order(customer_id);
CREATE INDEX idx_fact_order_date ON fact_order(order_date_id);
CREATE INDEX idx_fact_order_channel ON fact_order(channel_id);
CREATE INDEX idx_fact_order_status ON fact_order(order_status);


-- ===========================
-- Fact: Order Item
-- One row per product line in an order
-- ===========================
CREATE TABLE fact_order_item (
    order_item_id       BIGSERIAL PRIMARY KEY,
    order_id            BIGINT NOT NULL REFERENCES fact_order(order_id) ON DELETE CASCADE,
    product_id          BIGINT NOT NULL REFERENCES dim_product(product_id),
    quantity            INTEGER NOT NULL CHECK (quantity > 0),
    unit_price          NUMERIC(10,2) NOT NULL,       -- actual price charged per unit
    unit_discount       NUMERIC(10,2) NOT NULL DEFAULT 0,
    line_subtotal       NUMERIC(12,2) NOT NULL,       -- quantity * unit_price
    line_discount_total NUMERIC(12,2) NOT NULL DEFAULT 0,
    line_total          NUMERIC(12,2) NOT NULL        -- line_subtotal - line_discount_total
);

CREATE INDEX idx_fact_order_item_order ON fact_order_item(order_id);
CREATE INDEX idx_fact_order_item_product ON fact_order_item(product_id);
CREATE INDEX idx_fact_order_item_product_order ON fact_order_item(product_id, order_id);
