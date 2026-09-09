CREATE OR REPLACE TABLE bg_traffic.bg_traffic_gold.dim_gtfs_stop AS
SELECT
    ROW_NUMBER() OVER (ORDER BY stop_id) AS stop_sid,
    stop_id,
    stop_code,
    stop_name,
    stop_latitude,
    stop_longitude
FROM  bg_traffic.bg_traffic_silver.gtfs_stop;


ALTER TABLE bg_traffic.bg_traffic_gold.dim_gtfs_stop
ALTER COLUMN stop_sid SET NOT NULL;

ALTER TABLE bg_traffic.bg_traffic_gold.dim_gtfs_stop
ADD CONSTRAINT pk_dim_gtfs_stop PRIMARY KEY (stop_sid);