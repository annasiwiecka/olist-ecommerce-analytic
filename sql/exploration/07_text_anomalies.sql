-- Drill-down into anomalies found by 07_text_consistency.sql

SELECT geolocation_zip_code_prefix, '[' || geolocation_city || ']' AS city
FROM raw.geolocation
WHERE geolocation_city <> btrim(geolocation_city) OR geolocation_city = '';