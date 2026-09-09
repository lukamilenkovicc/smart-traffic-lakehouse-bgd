CREATE OR REPLACE TABLE bg_traffic.bg_traffic_gold.dim_pollutant AS
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY pollutant_name) AS pollutant_sid,
    pollutant_name,
    measurement_units AS units
FROM (
    SELECT DISTINCT pollutant_name, measurement_units
    FROM bg_traffic.bg_traffic_silver.openaq_measurements
);

ALTER TABLE bg_traffic.bg_traffic_gold.dim_pollutant
ALTER COLUMN pollutant_sid SET NOT NULL;


ALTER TABLE bg_traffic.bg_traffic_gold.dim_pollutant
ADD CONSTRAINT pk_dim_pollutant PRIMARY KEY (pollutant_sid);

ALTER TABLE bg_traffic.bg_traffic_gold.dim_pollutant
ADD CONSTRAINT uq_pollutant_name UNIQUE (pollutant_name);
