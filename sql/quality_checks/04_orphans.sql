-- ====== identify orphans =====

SELECT 'orders.customer_id -> customers' AS check_name, COUNT(*) AS issues
FROM raw.orders c 
WHERE NOT EXISTS (SELECT 1 FROM raw.customers p WHERE p.customer_id = c.customer_id)

UNION ALL
SELECT 'order_items.order_id -> orders', COUNT(*)
FROM raw.order_items c 
WHERE NOT EXISTS (SELECT 1 FROM raw.orders p WHERE p.order_id = c.order_id)

UNION ALL
SELECT 'order_items.product_id -> products', COUNT(*)
FROM raw.order_items c 
WHERE NOT EXISTS (SELECT 1 FROM raw.products p WHERE p.product_id = c.product_id)

UNION ALL
SELECT 'order_items.seller_id -> sellers', COUNT(*)
FROM raw.order_items c 
WHERE NOT EXISTS (SELECT 1 FROM raw.sellers p WHERE p.seller_id = c.seller_id)

UNION ALL
SELECT 'order_payments.order_id -> orders', COUNT(*)
FROM raw.order_payments c 
WHERE NOT EXISTS (SELECT 1 FROM raw.orders p WHERE p.order_id = c.order_id) 

UNION ALL
SELECT 'order_reviews.order_id -> orders', COUNT(*)
FROM raw.order_reviews c 
WHERE NOT EXISTS (SELECT 1 FROM raw.orders p WHERE p.order_id = c.order_id) 

UNION ALL
SELECT 'products.category -> translation', COUNT(*)
FROM raw.products c 
WHERE NOT EXISTS (SELECT 1 FROM raw.product_category_name_translation p WHERE p.product_category_name = c.product_category_name) 

UNION ALL
SELECT 'customer.zip -> geolocation', COUNT(*)
FROM raw.customers c 
WHERE NOT EXISTS (SELECT 1 FROM raw.geolocation p WHERE p.geolocation_zip_code_prefix = c.customer_zip_code_prefix) 

UNION ALL
SELECT 'seller.zip -> geolocation', COUNT(*)
FROM raw.sellers c 
WHERE NOT EXISTS (SELECT 1 FROM raw.geolocation p WHERE p.geolocation_zip_code_prefix = c.seller_zip_code_prefix) 

ORDER BY issues DESC;