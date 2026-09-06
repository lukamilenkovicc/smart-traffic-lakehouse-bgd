CREATE OR REPLACE TABLE bg_traffic.bg_traffic_gold.dim_road_segment AS
SELECT
    ROW_NUMBER() OVER (ORDER BY road_name) AS road_segment_sid,
    