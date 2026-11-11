-- Categories used by products but missing in the translation table

SELECT p.product_category_name, COUNT(*) AS product_category_name_translation
FROM raw.products p 
WHERE p.product_category_name IS NOT NULL
    AND NOT EXISTS (
        SELECT 1 FROM raw.product_category_name_translation t
        WHERE t.product_category_name = p.product_category_name
    )
GROUP BY p.product_category_name
