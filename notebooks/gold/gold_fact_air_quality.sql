CREATE TABLE IF NOT EXISTS bg_traffic.bg_traffic_gold.fact_air_quality(
    date_sid INT NOT NULL,
    time_sid INT NOT NULL,
    location_sid INT NOT NULL,
    pollutant_sid INT NOT NULL,
    municipality_sid INT NOT NULL,
    measurement_timestamp TIMESTAMP,
    pollutant_value DOUBLE,

    CONSTRAINT pk_fact_air_quality PRIMARY KEY(
        date_sid, time_sid, location_sid, pollutant_sid, municipality_sid
    ),
    CONSTRAINT fk_fact_air_quality_dim_date FOREIGN KEY (date_sid) REFERENCES bg_traffic.bg_traffic_gold.dim_date(date_sid),
    CONSTRAINT fk_fact_air_quality_dim_time FOREIGN KEY (time_sid) REFERENCES bg_traffic.bg_traffic_gold.dim_time(time_sid),
    CONSTRAINT fk_fact_air_quality_dim_air_station FOREIGN KEY (location_sid) REFERENCES bg_traffic.bg_traffic_gold.dim_air_station(location_sid),
    CONSTRAINT fk_fact_air_quality_dim_pollutant FOREIGN KEY (pollutant_sid) REFERENCES bg_traffic.bg_traffic_gold.dim_pollutant(pollutant_sid),
    CONSTRAINT fk_fact_air_quality_dim_municipality FOREIGN KEY (municipality_sid) REFERENCES bg_traffic.bg_traffic_gold.dim_municipality(municipality_sid) 
);

MERGE INTO bg_traffic.bg_traffic_gold.fact_air_quality AS target
USING (
    SELECT
        CAST(DATE_FORMAT(aq.measurement_timestamp, 'yyyyMMdd') AS INT) AS date_sid,
        CAST(DATE_FORMAT(aq.measurement_timestamp, 'HHmm') AS INT) AS time_sid,
        s.location_sid AS air_station_sid,
        p.pollutant_sid,
        m.municipality_sid,
        aq.measurement_timestamp,
        aq.measurement_value as pollutant_value
    FROM bg_traffic.bg_traffic_silver.openaq_measurements aq
    JOIN bg_traffic.bg_traffic_gold.dim_air_station s ON aq.location_id = s.location_id
    JOIN bg_traffic.bg_traffic_gold.dim_pollutant p ON aq.pollutant_name = p.pollutant_name
    JOIN bg_traffic.bg_traffic_silver.openaq_locations l ON aq.location_id = l.location_id
    JOIN bg_traffic.bg_traffic_gold.dim_municipality m ON l.municipality_name = m.municipality_name
    JOIN bg_traffic.bg_traffic_gold.dim_date d ON CAST(DATE_FORMAT(aq.measurement_timestamp, 'yyyyMMdd') AS INT) = d.date_sid
) AS source ON 
target.date_sid = source.date_sid AND
target.time_sid = source.time_sid AND
target.location_sid = source.air_station_sid AND
target.pollutant_sid = source.pollutant_sid AND
target.municipality_sid = source.municipality_sid
WHEN NOT MATCHED THEN INSERT(
    date_sid,
    time_sid,
    location_sid,
    pollutant_sid,
    municipality_sid,
    measurement_timestamp,
    pollutant_value
)
VALUES (
    source.date_sid,
    source.time_sid,
    source.air_station_sid,
    source.pollutant_sid,
    source.municipality_sid,
    source.measurement_timestamp,
    source.pollutant_value
);
