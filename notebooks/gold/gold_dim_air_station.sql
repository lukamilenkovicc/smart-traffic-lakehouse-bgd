CREATE OR REPLACE TABLE bg_traffic.bg_traffic_gold.dim_air_station AS
SELECT DISTINCT
    row_number() OVER (ORDER BY location_id) AS location_sid,
    location_id,
    location_name,
    latitude,
    longitude,
    provider_name

FROM bg_traffic.bg_traffic_silver.openaq_locations;

