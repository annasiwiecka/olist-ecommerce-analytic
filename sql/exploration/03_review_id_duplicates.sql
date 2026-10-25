-- Drill-down into duplicates found by 03_duplicate_keys.sql
-- 789 review_id values repeat in order_reviews

SELECT COUNT(*) AS duplicate_pairs
FROM (
    SELECT review_id, order_id
    FROM raw.order_reviews
    GROUP BY review_id, order_id
    HAVING COUNT(*) > 1
) d;