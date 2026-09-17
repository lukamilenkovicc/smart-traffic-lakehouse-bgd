CREATE TABLE IF NOT EXISTS bg_traffic.bg_traffic_gold.fact_transit_performance (

    date_sid INT NOT NULL,
    time_sid INT NOT NULL,
    route_sid INT NOT NULL,
    from_stop_sid INT NOT NULL,
    to_stop_sid INT NOT NULL,
    municipality_sid INT NOT NULL,
    trip_id STRING NOT NULL,
    planned_travel_time_sec INT,
    congestion_ratio DOUBLE,
    estimated_extra_time_sec DOUBLE,
    measurement_timestamp TIMESTAMP,
    CONSTRAINT pk_fact_transit_performance PRIMARY KEY (
        date_sid, time_sid, route_sid, from_stop_sid, to_stop_sid, municipality_sid, trip_id
    ),
    CONSTRAINT fk_fact_transit_performance_dim_date FOREIGN KEY (date_sid)REFERENCES bg_traffic.bg_traffic_gold.dim_date(date_sid),

    CONSTRAINT fk_fact_transit_performance_dim_time FOREIGN KEY (time_sid) REFERENCES bg_traffic.bg_traffic_gold.dim_time(time_sid),

    CONSTRAINT fk_fact_transit_performance_dim_route FOREIGN KEY (route_sid)REFERENCES bg_traffic.bg_traffic_gold.dim_gtfs_route(route_sid),

    CONSTRAINT fk_fact_transit_performance_dim_from_stop FOREIGN KEY (from_stop_sid)REFERENCES bg_traffic.bg_traffic_gold.dim_gtfs_stop(stop_sid),

    CONSTRAINT fk_fact_transit_performance_dim_to_stop FOREIGN KEY (to_stop_sid)REFERENCES bg_traffic.bg_traffic_gold.dim_gtfs_stop(stop_sid),

    CONSTRAINT fk_fact_transit_performance_dim_municipality FOREIGN KEY (municipality_sid)REFERENCES bg_traffic.bg_traffic_gold.dim_municipality(municipality_sid)
);

MERGE INTO bg_traffic.bg_traffic_gold.fact_transit_performance AS target
USING (
    SELECT
        tf.date_sid,
        CAST(
            DATE_FORMAT(TO_TIMESTAMP(st.arrival_time, 'HH:mm:ss'),'HHmm') AS INT) AS time_sid,
        r.route_sid,
        s_from.stop_sid AS from_stop_sid,
        s_to.stop_sid AS to_stop_sid,
        m.municipality_sid,
        st.trip_id,
        CASE WHEN UNIX_TIMESTAMP(st.arrival_time, 'HH:mm:ss') >= UNIX_TIMESTAMP(st.previous_departure_time, 'HH:mm:ss')
        THEN
        UNIX_TIMESTAMP(st.arrival_time, 'HH:mm:ss') - UNIX_TIMESTAMP(st.previous_departure_time, 'HH:mm:ss')
        ELSE
        UNIX_TIMESTAMP(st.arrival_time, 'HH:mm:ss') - UNIX_TIMESTAMP(st.previous_departure_time, 'HH:mm:ss') + 86400
        END AS planned_travel_time_sec,
        COALESCE(tf.avg_congestion, 1.0) AS congestion_ratio,
        ROUND(
            (UNIX_TIMESTAMP(st.arrival_time,'HH:mm:ss') - UNIX_TIMESTAMP(st.previous_departure_time, 'HH:mm:ss'))
            * (GREATEST( COALESCE(tf.avg_congestion, 1.0),1.0) - 1.0), 1) AS estimated_extra_time_sec,
        tf.traffic_measured_at AS measurement_timestamp
    FROM (
        SELECT
            st.trip_id,
            st.stop_id,
            st.arrival_time,
            st.departure_time,
            st.stop_sequence,
            LAG(st.stop_id) OVER (PARTITION BY st.trip_id ORDER BY st.stop_sequence) AS from_stop_id,
            LAG(st.departure_time) OVER (PARTITION BY st.trip_id ORDER BY st.stop_sequence) AS previous_departure_time
        FROM bg_traffic.bg_traffic_silver.gtfs_stop_time st
    ) st
    JOIN bg_traffic.bg_traffic_silver.gtfs_trip t ON st.trip_id = t.trip_id
    JOIN bg_traffic.bg_traffic_silver.gtfs_stop ss ON st.stop_id = ss.stop_id
    JOIN bg_traffic.bg_traffic_gold.dim_gtfs_route r ON t.route_id = r.route_id
    JOIN bg_traffic.bg_traffic_gold.dim_gtfs_stop s_to ON st.stop_id = s_to.stop_id
    JOIN bg_traffic.bg_traffic_gold.dim_gtfs_stop s_from ON st.from_stop_id = s_from.stop_id
    JOIN bg_traffic.bg_traffic_gold.dim_municipality m ON m.municipality_name = ss.municipality_name
    JOIN (
        SELECT
            date_sid,
            CAST(FLOOR(time_sid / 100) AS INT) AS flow_hour,
            municipality_sid,
            AVG(congestion_index) AS avg_congestion,
            MAX(measurement_timestamp) AS traffic_measured_at
        FROM bg_traffic.bg_traffic_gold.fact_traffic_flow
        GROUP BY date_sid, CAST(FLOOR(time_sid / 100) AS INT), municipality_sid
    ) tf ON tf.flow_hour = CAST(FLOOR(CAST(DATE_FORMAT(TO_TIMESTAMP(st.arrival_time,'HH:mm:ss'),'HHmm') AS INT) / 100) AS INT)
        AND tf.municipality_sid = m.municipality_sid
    WHERE
        st.from_stop_id IS NOT NULL
        AND st.previous_departure_time IS NOT NULL
        AND st.arrival_time IS NOT NULL
) AS source
ON
target.date_sid = source.date_sid AND 
target.time_sid = source.time_sid AND 
target.route_sid = source.route_sid AND 
target.from_stop_sid = source.from_stop_sid AND 
target.to_stop_sid = source.to_stop_sid AND 
target.municipality_sid = source.municipality_sid AND target.trip_id = source.trip_id
WHEN NOT MATCHED THEN INSERT (
    date_sid,
    time_sid,
    route_sid,
    from_stop_sid,
    to_stop_sid,
    municipality_sid,
    trip_id,
    planned_travel_time_sec,
    congestion_ratio,
    estimated_extra_time_sec,
    measurement_timestamp
)

VALUES (
    source.date_sid,
    source.time_sid,
    source.route_sid,
    source.from_stop_sid,
    source.to_stop_sid,
    source.municipality_sid,
    source.trip_id,
    source.planned_travel_time_sec,
    source.congestion_ratio,
    source.estimated_extra_time_sec,
    source.measurement_timestamp
);
