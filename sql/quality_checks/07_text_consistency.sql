-- ===== cities and states =====

SELECT 'customers.customer_city not lowercase' AS check_name, COUNT(*) AS issues
FROM raw.customers WHERE customer_city <> LOWER(customer_city)

UNION ALL  
SELECT 'sellers.seller_city not lowercase', COUNT(*)
FROM raw.sellers WHERE seller_city <> LOWER(seller_city)

UNION ALL
SELECT 'geolocation.geolocation_city not lowercase', COUNT(*)
FROM raw.geolocation WHERE geolocation_city <> LOWER(geolocation_city)


UNION ALL 
SELECT 'geolocation.geolocation_city has accents', COUNT(*)
FROM raw.geolocation WHERE geolocation_city ~ '[^\x00-\x7F]'

UNION ALL
SELECT 'customers.customer_state not 2 uppercase letters', COUNT(*)
FROM raw.customers WHERE customer_state !~ '^[A-Z]{2}$'

UNION ALL
SELECT 'sellers.seller_state not 2 uppercase letters', COUNT(*)
FROM raw.sellers WHERE seller_state !~ '^[A-Z]{2}$'

UNION ALL
SELECT 'geolocation.geolocation_state not 2 uppercase letters', COUNT(*)
FROM raw.geolocation WHERE geolocation_state !~ '^[A-Z]{2}$'

ORDER BY issues DESC

-- ==== white spaces and empty strings in all text columns ====

-- SELECT string_agg(
--     format('SELECT %L AS check_name, COUNT(*) AS issues FROM raw.%I WHERE %I <> btrim(%I) OR %I = %L',
--     r.table_name || '.' || r.column_name || ': untrimmed or empty',
--     r.table_name, r.column_name, r.column_name, r.column_name, ''
--     ),
--     E'\nUNION ALL\n' ORDER BY r.table_name, r.ordinal_position
-- ) || E'\nORDER BY issues DESC;'

-- FROM information_schema.columns r 
-- JOIN information_schema.columns c
-- ON c.table_schema = 'clean'
-- AND c.table_name = r.table_name 
-- AND c.column_name = r.column_name 
-- WHERE r.table_schema = 'raw'
-- AND c.data_type IN ('character varying', 'text') -- with  \gexec in SQL Shell