CREATE OR REPLACE TABLE bg_traffic.bg_traffic_gold.dim_road_segment AS
SELECT
    ROW_NUMBER() OVER (ORDER BY road_name) AS road_segment_sid,
    road_name,
    frc AS road_category_id,
    length_of_road_section as length_of_road_segment_km,
    CASE
        WHEN frc = 'FRC0' THEN "Najvažniji putevi - autoputevi / glavne saobraćajnice"
        WHEN frc = 'FRC1' THEN "Glavni putevi / važni gradski koridori"
        WHEN frc = 'FRC2' THEN "Značajni regionalni / gradski putevi"
        WHEN frc = 'FRC3' THEN "Ostali važniji gradski putevi"
        WHEN frc = 'FRC4' THEN "Lokalni putevi"
        WHEN frc = 'FRC5' THEN "Manji lokalni putevi"
    END AS road_category,
    coordinates
FROM (
    SELECT DISTINCT
        road_name, FIRST(frc) as frc,FIRST(length_of_road_section) as length_of_road_section, FIRST(coordinates) AS coordinates
    FROM bg_traffic.bg_traffic_silver.tomtom_flow
    GROUP BY road_name
);

ALTER TABLE bg_traffic.bg_traffic_gold.dim_road_segment
ALTER COLUMN road_segment_sid SET NOT NULL;

ALTER TABLE bg_traffic.bg_traffic_gold.dim_road_segment
ADD CONSTRAINT pk_dim_road_segment PRIMARY KEY (road_segment_sid);
    
    