CREATE OR REPLACE TABLE bg_traffic.bg_traffic_gold.dim_date AS
SELECT
    CAST(DATE_FORMAT(date_value, 'yyyyMMdd') AS INT) AS date_sid,
    date_value AS full_date,
    YEAR(date_value) AS year,
    MONTH(date_value) AS month,
    DATE_FORMAT(date_value,'MMMM') AS month_name,
    DAYOFWEEK(date_value) AS day_of_week,
    CASE DAYOFWEEK(date_value)
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN  'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END AS day_of_week_name,
    CASE WHEN DAYOFWEEK(date_value) IN (1,7) THEN TRUE ELSE FALSE END AS is_weekend,
    QUARTER(date_value) AS quarter
FROM (
    SELECT EXPLODE(SEQUENCE(
        DATE('2026-08-01'),
        DATE('2028-12-31'),
        INTERVAL 1 DAY
    )) AS date_value
);

ALTER TABLE bg_traffic.bg_traffic_gold.dim_date
ALTER COLUMN date_sid SET NOT NULL;

ALTER TABLE bg_traffic.bg_traffic_gold.dim_date
ADD CONSTRAINT pk_dim_date PRIMARY KEY (date_sid);

