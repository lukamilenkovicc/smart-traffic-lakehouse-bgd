CREATE OR REPLACE TABLE bg_traffic.bg_traffic_gold.dim_incident AS
SELECT
    icon_category as category_code,
    CASE
        WHEN icon_category = 0 THEN 'unknown'
        WHEN icon_category = 1 THEN 'saobraćajna nesreća'
        WHEN icon_category = 2 THEN 'magla'
        WHEN icon_category = 3 THEN 'opasni uslovi'
        WHEN icon_category = 4 THEN 'jaka kiša'
        WHEN icon_category = 5 THEN 'led'
        WHEN icon_category = 6 THEN 'gužva / zastoj'
        WHEN icon_category = 7 THEN 'zatvorena traka'
        WHEN icon_category = 8 THEN 'zatvoren put'
        WHEN icon_category = 9 THEN 'radovi na putu'
        WHEN icon_category = 10 THEN 'jak vetar'
        WHEN icon_category = 11 THEN 'poplava'
        WHEN icon_category = 12 THEN 'pokvareno vozilo'
    END AS category_name
FROM (
    SELECT DISTINCT icon_category FROM bg_traffic.bg_traffic_silver.tomtom_incident
);


ALTER TABLE bg_traffic.bg_traffic_gold.dim_incident
ALTER COLUMN category_code SET NOT NULL;

ALTER TABLE bg_traffic.bg_traffic_gold.dim_incident
ADD CONSTRAINT pk_dim_incident PRIMARY KEY (category_code);