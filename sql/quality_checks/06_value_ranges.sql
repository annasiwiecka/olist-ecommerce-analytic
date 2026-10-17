-- business rules: values that are actually valid types but make no sens

WITH o AS (
    -- parse dates once
    SELECT 
        CASE 
            WHEN order_purchase_timestamp ~ '^\d{4}-\d{2}-\d{2}'
                THEN order_purchase_timestamp::timestamp
            ELSE to_timestamp(order_purchase_timestamp, 'DD/MM/YYYY HH24:MI')::timestamp
        END as purchased,
        order_approved_at::timestamp AS approved,
        order_delivered_carrier_date::timestamp AS to_carrier,
        order_delivered_customer_date::timestamp AS delivered,
        order_status
    FROM raw.orders 
)

-- price
SELECT 'order_items.price <= 0' AS check_name, COUNT(*) AS issues
FROM raw.order_items WHERE price::numeric <= 0

UNION ALL
SELECT 'order_items.freight_value < 0', COUNT(*)
FROM raw.order_items WHERE freight_value::numeric < 0

UNION ALL
SELECT 'order_payments.payment_value <= 0', COUNT(*)
FROM raw.order_payments WHERE payment_value::numeric <= 0

UNION ALL
SELECT 'order_payments.payment_installments < 1', COUNT(*)
FROM raw.order_payments WHERE payment_installments::integer < 1

-- scores and sizes

UNION ALL
SELECT 'order_reviews.review_score not in 1-5', COUNT(*)
FROM raw.order_reviews WHERE review_score::integer NOT BETWEEN 1 AND 5

UNION ALL
SELECT 'products.product_weight_g <= 0', COUNT(*)
FROM raw.products WHERE product_weight_g::integer <= 0

-- order timeline 

UNION ALL
SELECT 'orders: approved before purchase', COUNT(*)
FROM o WHERE approved < purchased 

UNION ALL
SELECT 'orders: sent to carrier before purchase', COUNT(*)
FROM o WHERE to_carrier < purchased

UNION ALL
SELECT 'orders: delivered before purchase', COUNT(*)
FROM o WHERE delivered < purchased

UNION ALL
SELECT 'orders: delivered but status not delivered', COUNT(*)
FROM o WHERE delivered IS NOT NULL AND order_status <> 'delivered'

-- review timeline 

UNION ALL
SELECT 'order_reviews: answered before created', COUNT(*)
FROM raw.order_reviews
WHERE review_answer_timestamp::timestamp < review_creation_date::timestamp 

ORDER BY issues DESC