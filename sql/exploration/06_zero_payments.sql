-- Drill-down into anomalies found by 06_value_ranges.sql

SELECT payment_type, payment_value, payment_installments, COUNT(*)
FROM raw.order_payments
WHERE payment_value::numeric <= 0
GROUP BY 1, 2, 3;
