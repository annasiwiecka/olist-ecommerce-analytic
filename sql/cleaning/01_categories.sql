-- load category translations into clean

-- translaions from raw

INSERT INTO clean.product_category_name_translation (product_category_name, product_category_name_english)
SELECT btrim(product_category_name), btrim(product_category_name_english)
FROM raw.product_category_name_translation;


-- manual translactions for categories in the source -> found with sql/exploration/01_untranslated_categories.sql

INSERT INTO clean.product_category_name_translation (product_category_name, product_category_name_english)
VALUES ('portateis_cozinha_e_preparadores_de_alimentos', 'portable_kitchen_and_food_preparers'), ('pc_gamer', 'pc_gamer');


-- missing translactions

INSERT INTO clean.product_category_name_translation (product_category_name, product_category_name_english)
SELECT DISTINCT btrim(p.product_category_name), btrim(p.product_category_name)
FROM raw.products p
WHERE p.product_category_name IS NOT NULL
ON CONFLICT (product_category_name) DO NOTHING;


-- 'unknown' category

INSERT INTO clean.product_category_name_translation (product_category_name, product_category_name_english) 
VALUES ('unknown', 'unknown');
