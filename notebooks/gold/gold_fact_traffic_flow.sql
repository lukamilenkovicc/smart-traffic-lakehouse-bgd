CREATE TABLE IF NOT EXISTS bg_traffic.bg_traffic_gold.fact_traffic_flow (
    date_sid INT NOT NULL,
    time_sid INT NOT NULL,
    road_segment_sid INT NOT NULL,
    municipality_sid INT NOT NULL,
    current_speed_kmh DOUBLE,
    free_flow_speed_kmh DOUBLE,
    current_travel_time_sec INT,
    free_flow_travel_time_sec INT,
    congestion_index DOUBLE,
    measurement_timestamp TIMESTAMP,

    CONSTRAINT pk_fact_traffic_flow PRIMARY KEY(
        date_sid, time_sid, road_segment_sid, municipality_sid
    ),

    CONSTRAINT fk_fact_traffic_flow_dim_date FOREIGN KEY (date_sid) REFERENCES bg_traffic.bg_traffic_gold.dim_date(date_sid),
    CONSTRAINT fk_fact_traffic_flow_dim_time FOREIGN KEY (time_sid) REFERENCES bg_traffic.bg_traffic_gold.dim_time(time_sid),
    CONSTRAINT fk_fact_traffic_flow_dim_road_segment FOREIGN KEY (road_segment_sid) REFERENCES bg_traffic.bg_traffic_gold.dim_road_segment(road_segment_sid),
    CONSTRAINT fk_fact_traffic_flow_dim_municipality FOREIGN KEY (municipality_sid) REFERENCES bg_traffic.bg_traffic_gold.dim_municipality(municipality_sid)
);


MERGE INTO bg_traffic.bg_traffic_gold.fact_traffic_flow AS target
USING (
    SELECT
        CAST(DATE_FORMAT(tf.measurement_timestamp,'yyyyMMdd') AS INT) AS date_sid,
        CAST(DATE_FORMAT(tf.measurement_timestamp, 'HHmm') AS INT) AS time_sid,
        r.road_segment_sid,
        m.municipality_sid,
        tf.current_speed AS current_speed_kmh,
        tf.free_flow_speed AS free_flow_speed_kmh,
        tf.current_travel_time AS current_travel_time_sec,
        tf.free_flow_travel_time AS free_flow_travel_time_sec,
        ROUND(tf.current_travel_time / NULLIF(tf.free_flow_travel_time,0), 2) AS congestion_index,
        tf.measurement_timestamp
    FROM bg_traffic.bg_traffic_silver.tomtom_flow tf 
    JOIN bg_traffic.bg_traffic_gold.dim_date d ON CAST(DATE_FORMAT(tf.measurement_timestamp,'yyyyMMdd') as INT) = d.date_sid
    JOIN bg_traffic.bg_traffic_gold.dim_road_segment r ON tf.road_name = r.road_name
    JOIN bg_traffic.bg_traffic_gold.dim_municipality m ON tf.municipality_name = m.municipality_name
) AS source ON
target.date_sid = source.date_sid AND
target.time_sid = source.time_sid AND
target.road_segment_sid = source.road_segment_sid AND
target.municipality_sid = source.municipality_sid
WHEN NOT MATCHED THEN INSERT(
    date_sid,
    time_sid,
    road_segment_sid,
    municipality_sid,
    current_speed_kmh,
    free_flow_speed_kmh,
    current_travel_time_sec,
    free_flow_travel_time_sec,
    congestion_index,
    measurement_timestamp
)
VALUES (
    source.date_sid,
    source.time_sid,
    source.road_segment_sid,
    source.municipality_sid,
    source.current_speed_kmh,
    source.free_flow_speed_kmh,
    source.current_travel_time_sec,
    source.free_flow_travel_time_sec,
    source.congestion_index,
    source.measurement_timestamp
);



