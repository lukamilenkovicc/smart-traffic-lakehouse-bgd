CREATE OR REPLACE TABLE bg_traffic.bg_traffic_gold.dim_time AS
SELECT
    CAST(DATE_FORMAT(time_value, 'HHmm') AS INT) AS time_sid,
    DATE_FORMAT(time_value, 'HH:mm') AS time_of_day,
    HOUR(time_value) AS hour_24,
    MINUTE(time_value) AS minute_of_houe,
    CASE
        WHEN HOUR(time_value) BETWEEN 7 AND 9 THEN 'Jutarnji špic'
        WHEN HOUR(time_value) BETWEEN 16 AND 18 THEN 'Popodnevni špic'
        WHEN HOUR(time_value) BETWEEN 7 AND 9 THEN 'Jutarnji špic'
        WHEN HOUR(time_value) BETWEEN 22 AND 23 OR HOUR(time_value) BETWEEN 0 AND 5 THEN 'Noćni saobraćaj'
        ELSE 'Redovan saobraćaj van špica'
    END AS traffic_period_of_day,
    CASE 
        WHEN HOUR(time_value) BETWEEN 6 AND 11 THEN 'Jutro'
        WHEN HOUR(time_value) BETWEEN 12 AND 17 THEN 'Popodne'
        WHEN HOUR(time_value) BETWEEN 18 AND 22 THEN 'Veče'
        ELSE 'Noć'
    END AS day_period
FROM (
    SELECT EXPLODE(SEQUENCE(
        TIMESTAMP('2026-01-01 00:00:00'),
        TIMESTAMP('2026-01-01 23:59:59'),
        INTERVAL 1 MINUTE    
    )) AS time_value
);


