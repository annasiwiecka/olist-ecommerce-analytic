-- load products into clean
-- missing category -> unknown, weight 0 -> NULL (product can't wight nothing)

INSERT INTO clean.products (product_id, product_category_name, product_name_lenght, product_description_lenght, 
                            product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm)
SELECT btrim(product_id),
        COALESCE(btrim(product_category_name), 'unknown'),
        product_name_lenght::integer,
        product_description_lenght::integer,
        product_photos_qty::integer,
        NULLIF(product_weight_g::integer, 0),
        product_length_cm::integer,
        product_height_cm::integer,
        product_width_cm::integer
FROM raw.products;