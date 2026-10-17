-- Drill-down into anomalies found by 06_value_ranges.sql

SELECT order_status, COUNT(*)
FROM raw.orders
WHERE order_delivered_customer_date IS NOT NULL
AND order_status <> 'delivered'
GROUP BY 1;