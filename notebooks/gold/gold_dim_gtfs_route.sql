CREATE OR REPLACE TABLE bg_traffic.bg_traffic_gold.dim_gtfs_route AS
SELECT
    ROW_NUMBER() OVER (ORDER BY r.route_id) AS route_sid,
    r.route_id,
    r.route_short_name,
    r.route_long_name,
    r.route_type AS route_type_id,
    CASE
        WHEN r.route_type = 0 THEN 'Tramvaj'
        WHEN r.route_type = 3 THEN 'Autobus'
        WHEN r.route_type = 11 THEN 'Trolejbus'
        WHEN r.route_type = 2 THEN 'Železnica'
    END AS route_type_name,
    d.total_distance_km

FROM bg_traffic.bg_traffic_silver.gtfs_route r LEFT JOIN (
    SELECT 
        t.route_id,
        MAX(s.shape_dist_traveled) as total_distance_km
    FROM bg_traffic.bg_traffic_silver.gtfs_trip t
    JOIN bg_traffic.bg_traffic_silver.gtfs_shape s ON t.shape_id = s.shape_id
    GROUP BY t.route_id 
) d ON r.route_id = d.route_id;