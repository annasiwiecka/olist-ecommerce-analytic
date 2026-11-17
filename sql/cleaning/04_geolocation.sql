-- loead gelocation into clean
-- fix 3 city names

CREATE EXTENSION IF NOT EXISTS unaccent;

INSERT INTO clean.geolocation (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state)
SELECT zip, lat, lng, CASE city
                        WHEN 'maceia³' THEN 'maceio'
                        WHEN 'sa£o paulo'   THEN 'sao paulo'
                        WHEN '´teresopolis' THEN 'teresopolis'
                        ELSE city
                    END,
                    state
FROM (
SELECT geolocation_zip_code_prefix::integer AS zip, 
    geolocation_lat::double precision AS lat, 
    geolocation_lng::double precision AS lng,  
    lower(btrim(unaccent(geolocation_city))) AS city, 
    upper(btrim(geolocation_state)) AS state
FROM raw.geolocation) g;