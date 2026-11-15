-- loead gelocation into clean

CREATE EXTENSION IF NOT EXISTS unaccent;

INSERT INTO clean.geolocation (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state)
SELECT geolocation_zip_code_prefix::integer, geolocation_lat::double precision, geolocation_lng::double precision,  
    lower(btrim(unaccent(geolocation_city))), upper(btrim(geolocation_state))
FROM raw.geolocation 