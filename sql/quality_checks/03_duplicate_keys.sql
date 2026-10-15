-- ========= duplicate keys =========

SELECT 'customers: duplicate customer_id' AS check_name, COUNT(*) AS issues
FROM (SELECT customer_id FROM raw.customers
      GROUP BY customer_id HAVING COUNT(*) > 1) d

UNION ALL
SELECT 'orders: duplicate order_id', COUNT(*)
FROM (SELECT order_id FROM raw.orders
      GROUP BY order_id HAVING COUNT(*) > 1) d

UNION ALL
SELECT 'products: duplicate product_id', COUNT(*)
FROM (SELECT product_id FROM raw.products
      GROUP BY product_id HAVING COUNT(*) > 1) d

UNION ALL
SELECT 'sellers: duplicate seller_id', COUNT(*)
FROM (SELECT seller_id FROM raw.sellers
      GROUP BY seller_id HAVING COUNT(*) > 1) d

UNION ALL
SELECT 'order_reviews: duplicate review_id', COUNT(*)
FROM (SELECT review_id FROM raw.order_reviews
      GROUP BY review_id HAVING COUNT(*) > 1) d

UNION ALL
SELECT 'order_items: duplicate (order_id, order_item_id)', COUNT(*)
FROM (SELECT order_id, order_item_id FROM raw.order_items
      GROUP BY order_id, order_item_id HAVING COUNT(*) > 1) d

UNION ALL
SELECT 'order_payments: duplicate (order_id, payment_sequential)', COUNT(*)
FROM (SELECT order_id, payment_sequential FROM raw.order_payments
      GROUP BY order_id, payment_sequential HAVING COUNT(*) > 1) d

UNION ALL
SELECT 'product_category_name_translation: duplicate product_category_name', COUNT(*)
FROM (SELECT product_category_name FROM raw.product_category_name_translation
      GROUP BY product_category_name HAVING COUNT(*) > 1) d

ORDER BY issues DESC;
