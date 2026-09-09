CREATE OR REPLACE TABLE bg_traffic.bg_traffic_gold.dim_air_station AS
SELECT DISTINCT
    row_number() OVER (ORDER BY location_id) AS location_sid,
    location_id,
    location_name,
    latitude,
    longitude,
    provider_name

FROM bg_traffic.bg_traffic_silver.openaq_locations;


ALTER TABLE bg_traffic.bg_traffic_gold.dim_air_station
ALTER COLUMN location_sid SET NOT NULL;

ALTER TABLE bg_traffic.bg_traffic_gold.dim_air_station
ADD CONSTRAINT pk_dim_air_station PRIMARY KEY (location_sid);

