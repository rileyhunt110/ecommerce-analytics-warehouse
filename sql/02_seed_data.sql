-- =========================================
-- 02_seed_data.sql
-- Seed data for E-commerce Analytics Warehouse
-- - dim_date
-- - dim_channel
-- =========================================

-- Make sure we're in the right DB (if running interactively)
-- \c ecommerce_warehouse

-- ===========================
-- Seed dim_date
-- ===========================
-- We'll generate a date dimension from 2020-01-01 to 2024-12-31.
-- Adjust the range as needed later.

INSERT INTO dim_date (
    date_id,
    date_actual,
    year,
    quarter,
    month,
    day,
    day_of_week,
    is_weekend,
    week_of_year
)
SELECT
    -- date_id as yyyymmdd integer
    (EXTRACT(YEAR FROM d)::INT * 10000
     + EXTRACT(MONTH FROM d)::INT * 100
     + EXTRACT(DAY FROM d)::INT)        AS date_id,
    d                                   AS date_actual,
    EXTRACT(YEAR FROM d)::INT           AS year,
    EXTRACT(QUARTER FROM d)::INT        AS quarter,
    EXTRACT(MONTH FROM d)::INT          AS month,
    EXTRACT(DAY FROM d)::INT            AS day,
    EXTRACT(ISODOW FROM d)::INT         AS day_of_week,  -- 1=Mon..7=Sun
    CASE WHEN EXTRACT(ISODOW FROM d) IN (6, 7) THEN TRUE ELSE FALSE END AS is_weekend,
    EXTRACT(WEEK FROM d)::INT           AS week_of_year
FROM
    GENERATE_SERIES(
        DATE '2020-01-01',
        DATE '2024-12-31',
        INTERVAL '1 day'
    ) AS gs(d)
ON CONFLICT (date_id) DO NOTHING;  -- in case you rerun this script


-- ===========================
-- Seed dim_channel
-- ===========================
-- Basic marketing / acquisition channels.

INSERT INTO dim_channel (channel_name, channel_group, details) VALUES
    ('Direct',           'Owned',   'Direct traffic: URL or app open'),
    ('Organic Search',   'Organic', 'Search engine results (SEO)'),
    ('Paid Search',      'Paid',    'Search ads (PPC)'),
    ('Email',            'Owned',   'Email campaigns and newsletters'),
    ('Social',           'Organic', 'Organic social media traffic'),
    ('Paid Social',      'Paid',    'Paid ads on social platforms'),
    ('Referral',         'Organic', 'Traffic from other websites'),
    ('Display Ads',      'Paid',    'Banner/display ad campaigns')
ON CONFLICT DO NOTHING;
