-- Business impact of data quality issues found in sql/quality_checks/.

-- ====== orphan order items =====
-- how much revenue belongs to orders that no longer exist?

SELECT COUNT(*) as orphan_items,
    SUM(price::numeric + freight_value::numeric) AS orphan_value
FROM raw.order_items c 
WHERE NOT EXISTS (SELECT 1 FROM raw.orders p where p.order_id = c.order_id);


-- =====  duplicated orders ===== 
-- by how much would revenue be overstated if items were joined to orders wihout removing duplicates?

SELECT 
    (SELECT SUM(oi.price::numeric)
    FROM raw.order_items oi
    JOIN raw.orders o ON o.order_id = oi.order_id
    ) AS revenue_with_duplicates,

    (SELECT SUM(oi.price::numeric)
    FROM raw.order_items oi 
    WHERE EXISTS (SELECT 1 FROM raw.orders o WHERE o.order_id = oi.order_id) 
    ) AS revenue_correct;


-- ===== products without category =====
-- what share of revenue is missing from a category ranking?

SELECT ROUND(100.0 * SUM(oi.price::numeric) 
    FILTER (WHERE p.product_category_name IS NULL) / SUM(oi.price::numeric), 1) AS pct_revenue_without_category
FROM raw.order_items oi
JOIN raw.products p ON p.product_id = oi.product_id;


-- ===== mixed date formats =====
-- how many orders would land in the wrong month without any error?

SELECT COUNT(*) AS silently_misdated_on_mdy_server
FROM raw.orders
WHERE order_purchase_timestamp ~ '^\d{2}/\d{2}/\d{4}'
AND split_part(order_purchase_timestamp, '/', 1)::int <= 12;


-- ===== inconsistent city names =====
-- how many fake cities would appear on a regional chart?

SELECT COUNT(DISTINCT customer_city) AS city_spellings,
       COUNT(DISTINCT LOWER(btrim(customer_city))) AS real_cities
FROM raw.customers;


-- ===== negative prices =====
-- by how much is revenue understated?

SELECT SUM(price::numeric) AS negative_total
FROM raw.order_items
WHERE price::numeric < 0;