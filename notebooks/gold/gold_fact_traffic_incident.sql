CREATE TABLE IF NOT EXISTS bg_traffic.bg_traffic_gold.fact_traffic_incident (
    date_sid INT NOT NULL,
    time_sid INT NOT NULL,
    category_code INT NOT NULL,
    municipality_sid INT NOT NULL,
    road_segment_sid INT NOT NULL,
    start_longitude DOUBLE,
    start_latitude DOUBLE,
    end_longitude DOUBLE,
    end_latitude DOUBLE,
    coordinates ARRAY<STRUCT<
        longitude: DOUBLE,
        latitude: DOUBLE
    >>,

    CONSTRAINT pk_fact_traffic_incident PRIMARY KEY (
        date_sid, time_sid, category_code, municipality_sid, road_segment_sid
    ),

    CONSTRAINT fk_fact_traffic_incident_dim_date FOREIGN KEY (date_sid) REFERENCES bg_traffic.bg_traffic_gold.dim_date(date_sid),
    CONSTRAINT fk_fact_traffic_incident_dim_time FOREIGN KEY (time_sid) REFERENCES bg_traffic.bg_traffic_gold.dim_time(time_sid),
    CONSTRAINT fk_fact_traffic_incident_dim_incident FOREIGN KEY (category_code) REFERENCES bg_traffic.bg_traffic_gold.dim_incident(category_code),
    CONSTRAINT fk_fact_traffic_incident_dim_municipality FOREIGN KEY (municipality_sid) REFERENCES bg_traffic.bg_traffic_gold.dim_municipality(municipality_sid),
    CONSTRAINT fk_fact_traffic_incident_dim_road_segment FOREIGN KEY (road_segment_sid) REFERENCES bg_traffic.bg_traffic_gold.dim_road_segment(road_segment_sid)
);

MERGE INTO bg_traffic.bg_traffic_gold.fact_traffic_incident AS target
USING (
    SELECT
        CAST(DATE_FORMAT(ti.fetched_at, 'yyyyMMdd') AS INT) AS date_sid,
        CAST(DATE_FORMAT(ti.fetched_at, 'HHmm') AS INT) AS time_sid,
        i.category_code,
        r.road_segment_sid,
        m.municipality_sid,
        ti.start_longitude,
        ti.start_latitude,
        ti.end_longitude,
        ti.end_latitude,
        ti.coordinates
    FROM bg_traffic.bg_traffic_silver.tomtom_incident ti
    JOIN bg_traffic.bg_traffic_gold.dim_incident i ON ti.icon_category = i.category_code
    JOIN bg_traffic.bg_traffic_gold.dim_road_segment r ON ti.road_name = r.road_name
    JOIN bg_traffic.bg_traffic_gold.dim_municipality m ON ti.municipality_name = m.municipality_name
    JOIN bg_traffic.bg_traffic_gold.dim_date d ON CAST(DATE_FORMAT(ti.fetched_at, 'yyyyMMdd') AS INT) = d.date_sid
) AS source ON
target.date_sid = source.date_sid AND
target.time_sid = source.time_sid AND
target.category_code = source.category_code AND
target.municipality_sid = source.municipality_sid AND
target.road_segment_sid = source.road_segment_sid
WHEN NOT MATCHED THEN INSERT (
    date_sid,
    time_sid,
    category_code,
    municipality_sid,
    road_segment_sid,
    start_longitude,
    start_latitude,
    end_longitude,
    end_latitude,
    coordinates
)
VALUES (
    source.date_sid,
    source.time_sid,
    source.category_code,
    source.municipality_sid,
    source.road_segment_sid,
    source.start_longitude,
    source.start_latitude,
    source.end_longitude,
    source.end_latitude,
    source.coordinates
);


