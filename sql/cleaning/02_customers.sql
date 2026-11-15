-- load customers into clean 

CREATE EXTENSION IF NOT EXISTS unaccent;

INSERT INTO clean.customers (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
SELECT btrim(customer_id), btrim(customer_unique_id), customer_zip_code_prefix::integer, lower(unaccent(btrim(customer_city))), upper(btrim(customer_state))
FROM raw.customers;

