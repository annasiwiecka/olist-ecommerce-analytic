-- load sellers into clean

CREATE EXTENSION IF NOT EXISTS unaccent;

INSERT INTO clean.sellers (seller_id, seller_zip_code_prefix, seller_city, seller_state)
SELECT btrim(seller_id), seller_zip_code_prefix::integer, lower(btrim(unaccent(seller_city))), upper(btrim(seller_state))
FROM raw.sellers;