-- load orders into clean
-- for duplicates -> keeping one row per order_id and preferring ne with ISO date (damaged dates lost seconds)
-- for purchase dates -> parsing ISO and DD/MM/YYYY with explicit formats

INSERT INTO clean.orders (order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at, 
                order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date)
SELECT DISTINCT ON (order_id) btrim(order_id), btrim(customer_id), btrim(order_status),
    CASE 
        WHEN order_purchase_timestamp ~ '^\d{4}-\d{2}-\d{2}'
            THEN to_timestamp(order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS')
        ELSE to_timestamp(order_purchase_timestamp, 'DD/MM/YYYY HH24:MI')
    END::timestamp,
    order_approved_at::timestamp,
    order_delivered_carrier_date::timestamp,
    order_delivered_customer_date::timestamp,
    order_estimated_delivery_date::timestamp
FROM raw.orders 
ORDER BY order_id, (order_purchase_timestamp ~ '^\d{4}-\d{2}-\d{2}') DESC;