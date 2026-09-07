CREATE OR REPLACE TABLE bg_traffic.bg_traffic_gold.dim_poluttant AS
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY pollutant_name) AS pollutant_sid,
    pollutant_name,
    measurement_units AS units
FROM (
    SELECT DISTINCT pollutant_name, measurement_units
    FROM bg_traffic.bg_traffic_silver.openaq_measurements
);
