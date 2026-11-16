# Smart Traffic Lakehouse BGD

A Data Lakehouse for monitoring **traffic, public transport, weather and air quality in Belgrade**. The project collects data from several public APIs and open datasets, processes it through a Medallion architecture (Bronze → Silver → Gold) on Databricks with Delta Lake, and exposes a star-schema model to a Power BI report.

> Developed as a bachelor thesis project at FON, University of Belgrade.

---

## Table of Contents

1. [Project Purpose](#1-project-purpose)
2. [Architecture](#2-architecture)
3. [Data Sources](#3-data-sources)
4. [Repository Structure](#4-repository-structure)
5. [Pipeline Layers](#5-pipeline-layers)
6. [Gold Data Model](#6-gold-data-model)
7. [Tech Stack](#7-tech-stack)
8. [Setup](#8-setup)
9. [Running the Pipeline](#9-running-the-pipeline)
10. [Reporting (Power BI)](#10-reporting-power-bi)
11. [Known Limitations and Next Steps](#11-known-limitations-and-next-steps)

---

## 1. Project Purpose

Belgrade traffic data is scattered across different providers and formats. This project integrates it into a single, analytics-ready lakehouse so that questions like these can be answered in one place:

- How congested are key roads and bridges, and how does that change by hour, weekday and weather?
- Where and when do traffic incidents (accidents, closed lanes, road works) occur?
- How much extra travel time does congestion add to public transport (tram, bus, trolleybus) routes?
- How does air quality (PM, NO₂ etc.) relate to traffic intensity across municipalities?

**Main goal:** build a reproducible, incremental data pipeline and a dimensional model for reporting on Belgrade's traffic and urban environment.

---

## 2. Architecture

```
 External sources                 Databricks (Unity Catalog: bg_traffic)
┌──────────────────┐   fetch   ┌─────────────┐  Auto Loader / batch  ┌──────────┐  stream + MERGE  ┌──────────┐  SQL MERGE  ┌────────────┐
│ TomTom Traffic   │──────────▶│ Landing     │──────────────────────▶│ BRONZE   │─────────────────▶│ SILVER   │────────────▶│ GOLD       │──▶ Power BI
│ Open-Meteo       │  (Python) │ Volumes     │                       │ raw Delta│  clean, typed,   │ validated│  star schema│ facts+dims │
│ OpenAQ           │           │ (JSON / CSV)│                       │ tables   │  deduplicated    │ Delta    │             │            │
│ GTFS (data.gov.rs)│          └─────────────┘                       └──────────┘  geo-enriched    └──────────┘             └────────────┘
└──────────────────┘
```

| Layer | Schema | Purpose |
|---|---|---|
| Landing | `/Volumes/bg_traffic/bg_traffic_bronze/landing/...` | Raw API responses stored as timestamped JSON files (GTFS as extracted CSV/TXT files) |
| Bronze | `bg_traffic.bg_traffic_bronze` | Raw data as Delta tables with ingestion metadata |
| Silver | `bg_traffic.bg_traffic_silver` | Flattened, typed, validated, deduplicated and geo-enriched data |
| Gold | `bg_traffic.bg_traffic_gold` | Dimensional model (facts and dimensions) for reporting |

---

## 3. Data Sources

| Source | What it provides | Frequency | Auth |
|---|---|---|---|
| **TomTom Traffic Flow API** | Current speed, free-flow speed, travel times and road geometry for 15 monitored Belgrade locations (e.g. Gazela, Brankov most, Autokomanda, Pančevački most, Most na Adi, Nemanjina, Savska) | Frequent | API key |
| **TomTom Traffic Incidents API** | Incidents inside the Belgrade bounding box (accidents, closures, road works, etc.) | Frequent | API key |
| **Open-Meteo API** | Current temperature, humidity, precipitation, rain, showers, snowfall, wind speed | Frequent | None |
| **OpenAQ API (v3)** | Air-quality stations within 5 km of central Belgrade and their latest measurements | Measurements: frequent; locations: weekly | API key |
| **GTFS (data.gov.rs)** | Public transport static data: stops, routes, trips, stop times, shapes, calendar | Weekly | None |
| **Belgrade municipalities GeoJSON** | Polygons used to map coordinates to municipalities | Static | – |

---

## 4. Repository Structure

```
smart-traffic-lakehouse-bgd/
├── ingestion/                  # Standalone ingestion scripts (TomTom, Open-Meteo, GTFS)
├── src/                        # Fetch modules imported by the Databricks runner notebooks
│   ├── fetch_tomtom.py
│   ├── fetch_openmeteo.py
│   ├── fetch_openaq_locations.py
│   ├── fetch_openaq_measurements.py
│   └── fetch_gtfs.py
├── notebooks/
│   ├── bronze/                 # Raw → Bronze Delta tables + runner notebooks
│   ├── silver/                 # Bronze → Silver transformations + helper modules
│   │   ├── create_silver_tables.ipynb
│   │   ├── spatial.py          # Point-in-polygon municipality lookup (UDF)
│   │   └── road_length.py      # Road segment length via geodesic distance (UDF)
│   └── gold/                   # Dimension and fact SQL + weekly runner
├── power_bi/
│   └── smart_traffic_bgd_reporting.pbix
├── requirements.txt
└── README.md
```

---

## 5. Pipeline Layers

### 5.1 Ingestion (Landing)

Python scripts call the external APIs and write raw payloads to Unity Catalog Volumes. Each JSON file wraps the response with metadata (`source`, `fetched_at`, `request_url`).

- `fetch_tomtom()` – flow data for all monitored points plus incidents for the city bounding box.
- `fetch_openmeteo()` – current weather for Belgrade (44.8125, 20.4612).
- `fetch_openaq_locations()` / `fetch_openaq_measurements(location_id)` – stations and their latest readings.
- `fetch_gtfs()` – downloads the GTFS zip and extracts it into a date-stamped folder.

### 5.2 Bronze

Raw data as Delta tables, with no business logic.

- JSON sources are loaded incrementally with **Auto Loader** (`cloudFiles`, `availableNow` trigger, checkpointed), adding `_ingestion_timestamp` and `_source_file`.
- GTFS tables (`gtfs_stops`, `gtfs_routes`, `gtfs_trips`, `gtfs_stop_times`, `gtfs_shapes`, `gtfs_calendar`, `gtfs_calendar_dates`) are read from the latest dated folder and overwritten.
- Two runner notebooks orchestrate fetching:
  - `bronze_runner_frequent` – TomTom, Open-Meteo, OpenAQ measurements
  - `bronze_weekly_runner` – GTFS, OpenAQ locations

### 5.3 Silver

Cleaned and conformed tables, created in `create_silver_tables.ipynb` and populated by one notebook per source.

- **Flattening** of nested JSON (e.g. one row per road per measurement for TomTom flow).
- **Type casting** and timestamp normalisation.
- **Deduplication** on business keys (e.g. `road_name` + `measurement_timestamp`).
- **Validation rules**, for example: non-null keys, `current_speed >= 0`, `current_travel_time >= free_flow_travel_time`, `confidence` between 0 and 1, coordinates within Belgrade bounds, minimum segment length.
- **Geo-enrichment:** municipality name from coordinates (GeoPandas/Shapely) and road section length (GeoPy geodesic).
- **Incremental upserts** using Structured Streaming `foreachBatch` with Delta `MERGE`.

### 5.4 Gold

SQL notebooks build the dimensional model. Dimensions and facts are loaded with `MERGE`, using surrogate keys (`*_sid`) and primary/foreign key constraints. `gold_weekly_runner` refreshes dimensions and facts.

---

## 6. Gold Data Model

Star schema with shared conformed dimensions.

**Fact tables**

| Table | Grain | Key measures |
|---|---|---|
| `fact_traffic_flow` | date × time × road segment × municipality | current/free-flow speed, travel times, `congestion_index` |
| `fact_traffic_incident` | date × time × incident category × municipality × road segment | start/end coordinates, geometry |
| `fact_transit_performance` | date × time × route × from-stop × to-stop × municipality × trip | planned travel time, `congestion_ratio`, `estimated_extra_time_sec` |
| `fact_weather` | date × time | temperature, humidity, precipitation, rain, wind |
| `fact_air_quality` | date × time × station × pollutant × municipality | pollutant value |

**Dimension tables**

`dim_date`, `dim_time` (minute grain, with peak/off-peak and day-period labels), `dim_municipality` (with city zone), `dim_road_segment` (with FRC road category), `dim_incident`, `dim_gtfs_route`, `dim_gtfs_stop`, `dim_air_station`, `dim_pollutant`.

**Congestion index** = `current_travel_time / free_flow_travel_time` (1.0 means free flow; higher means more congestion).

---

## 7. Tech Stack

- **Platform:** Databricks (Unity Catalog, Volumes, Delta Lake, Structured Streaming / Auto Loader)
- **Languages:** Python (PySpark), SQL
- **Libraries:** `requests`, `python-dotenv`, GeoPandas, Shapely, GeoPy
- **Reporting:** Power BI

---

## 8. Setup

### Prerequisites

- A Databricks workspace with Unity Catalog enabled
- API keys for **TomTom** and **OpenAQ** (Open-Meteo and GTFS need none)

### Steps

1. **Clone the repository** (e.g. as a Databricks Repo).

   ```bash
   git clone https://github.com/lukamilenkovicc/smart-traffic-lakehouse-bgd.git
   cd smart-traffic-lakehouse-bgd
   ```

2. **Install dependencies.**

   ```bash
   pip install -r requirements.txt
   # Silver notebooks additionally need: geopandas, shapely, geopy
   ```

3. **Configure credentials** in a `.env` file in the project root (this file is git-ignored):

   ```env
   TOMTOM_API_KEY=your_tomtom_key
   OPENAQ_API_KEY=your_openaq_key
   ```

4. **Create the catalog structure** in Unity Catalog:
   - Catalog `bg_traffic` with schemas `bg_traffic_bronze`, `bg_traffic_silver`, `bg_traffic_gold`
   - Volume `landing` in the bronze schema
   - A volume `geo_podaci` in the silver schema containing `beograd_opstine.geojson`

5. **Create Silver tables** by running `notebooks/silver/create_silver_tables.ipynb`.

---

## 9. Running the Pipeline

Run in this order (each step can be scheduled as a Databricks Job):

| Step | Notebook | Suggested cadence |
|---|---|---|
| 1. Weekly ingestion | `notebooks/bronze/bronze_weekly_runner` | Weekly |
| 2. Frequent ingestion | `notebooks/bronze/bronze_runner_frequent` | Every few minutes / hourly |
| 3. Load Bronze | `notebooks/bronze/bronze_*` (TomTom, Open-Meteo, OpenAQ, GTFS) | After each ingestion |
| 4. Build Silver | `notebooks/silver/silver_*` | After Bronze |
| 5. Build Gold dimensions | `notebooks/gold/gold_dim_*.sql` (first run) | Once, then via runner |
| 6. Build Gold facts | `notebooks/gold/gold_fact_*.sql` and `gold_weekly_runner` | After Silver |

---

## 10. Reporting (Power BI)

The report `power_bi/smart_traffic_bgd_reporting.pbix` connects to the Gold schema and visualises congestion, incidents, transit delays, weather and air quality by time, road and municipality. Open it in Power BI Desktop and point the data source to your Databricks SQL warehouse.

---

## 11. Known Limitations and Next Steps

- Traffic flow covers 15 selected locations, not the whole road network.
- OpenAQ and Open-Meteo data are "latest/current" snapshots, so history depends on how often the pipeline runs.
- `dim_date` is generated for a fixed range (2026-08-01 to 2028-12-31) and needs extending later.
- Planned improvements: pipeline orchestration as Databricks Workflows, data-quality monitoring, automated tests, and predictive modelling (e.g. congestion forecasting).
