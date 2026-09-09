CREATE TABLE IF NOT EXISTS bg_traffic.bg_traffic_gold.fact_weather (
    date_sid INT NOT NULL,
    time_sid INT NOT NULL,
     weather_timestamp TIMESTAMP NOT NULL,
    temperature_c DOUBLE,
    relative_humidity DOUBLE,
    wind_speed_kmh DOUBLE,
    precipitation_mm DOUBLE,
    rain_mm DOUBLE,

    CONSTRAINT pk_fact_weather PRIMARY KEY (date_sid, time_sid),
    CONSTRAINT fk_fact_weather_dim_date FOREIGN KEY (date_sid) REFERENCES bg_traffic.bg_traffic_gold.dim_date(date_sid),
    CONSTRAINT fk_fact_weather_dim_time FOREIGN KEY (time_sid) REFERENCES bg_traffic.bg_traffic_gold.dim_time(time_sid)

   
);


MERGE INTO bg_traffic.bg_traffic_gold.fact_weather target
USING (
    SELECT
        CAST(DATE_FORMAT(w.weather_timestamp, 'yyyyMMdd') AS INT) AS date_sid,
        CAST(DATE_FORMAT(w.weather_timestamp, 'HHmm') AS INT) AS time_sid,
        w.weather_timestamp,
        w.temperature_c,
        w.relative_humidity,
        w.precipitation_mm,
        w.wind_speed_kmh,
        w.rain_mm
    FROM bg_traffic.bg_traffic_silver.openmeteo w
    JOIN bg_traffic.bg_traffic_gold.dim_date d ON CAST(DATE_FORMAT(w.weather_timestamp,'yyyyMMdd') AS INT) = d.date_sid
    WHERE w.weather_timestamp IS NOT NULL                                                                   
) source
ON target.weather_timestamp = source.weather_timestamp
WHEN NOT MATCHED THEN INSERT (
    date_sid,
    time_sid,
    temperature_c,
    relative_humidity,
    precipitation_mm,
    wind_speed_kmh,
    rain_mm,
    weather_timestamp
)
VALUES (
    source.date_sid,
    source.time_sid,
    source.temperature_c,
    source.relative_humidity,
    source.precipitation_mm,
    source.wind_speed_kmh,
    source.rain_mm,
    source.weather_timestamp
);