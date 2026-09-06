CREATE OR REPLACE TABLE bg_traffic.bg_traffic_gold.dim_municipality AS

SELECT 
    0 AS municipality_sid,
    "Unknown" AS municipality_name,
    "Unknown" AS city_zone

UNION 

SELECT 
    row_number() OVER (ORDER BY municipality_name) AS municipality_sid,
    municipality_name,
    CASE
        WHEN municipality_name IN ('STARI GRAD', 'VRAČAR', 'SAVKSI VENAC')
            THEN 'Centralna zona - Zona 1'
        WHEN municipality_name IN ('NOVI BEOGRAD','ZEMUN','ZVEZDARA','PALILULA','VOŽDOVAC','ČUKARICA')
            THEN 'Siri centar - Zona 2'
        ELSE 'Zona 3'
    END as city_zone
FROM (
    SELECT DISTINCT municipality_name
    FROM bg_traffic.bg_traffic_silver.gtfs_stop
    WHERE municipality_name IS NOT NULL AND municipality_name != 'Unknown'

    UNION

    SELECT DISTINCT municipality_name
    FROM bg_traffic.bg_traffic_silver.tomtom_flow
    WHERE municipality_name IS NOT NULL AND municipality_name != 'Unknown'

    UNION

    SELECT DISTINCT municipality_name
    FROM bg_traffic.bg_traffic_silver.tomtom_incident
    WHERE municipality_name IS NOT NULL AND municipality_name != 'Unknown'
    
    UNION 

    SELECT DISTINCT municipality_name
    FROM bg_traffic.bg_traffic_silver.openaq_locations
    WHERE municipality_name IS NOT NULL AND municipality_name != 'Unknown'

)
ORDER BY municipality_sid;