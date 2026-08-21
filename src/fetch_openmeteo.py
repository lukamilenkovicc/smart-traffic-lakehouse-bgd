import os
import json
import requests
from datetime import datetime as datum, timezone


LATITUDE = 44.8125
LONGITUDE = 20.4612

OUTPUT_DIR = "/Volumes/bg_traffic/bg_traffic_bronze/landing/openmeteo"


URL = (
    f"https://api.open-meteo.com/v1/forecast"
    f"?latitude={LATITUDE}&longitude={LONGITUDE}"
    f"&current=temperature_2m,relative_humidity_2m,precipitation,rain,showers,snowfall,wind_speed_10m"
    f"&timezone=Europe%2FBelgrade"
)

def fetch_openmeteo():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    try:
        response = requests.get(URL, timeout=10)
        response.raise_for_status()
        data = response.json()

        payload = {
            "source": "open-meteo",
            "fetched_at": datum.now(timezone.utc).isoformat(),
            "request_url": URL,
            "data": data,
        }

        timestamp_str = datum.now().strftime("%Y-%m-%d_%H%M%S")
        filepath = f"{OUTPUT_DIR}/openmeteo_{timestamp_str}.json"




        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(payload, f, indent=2, ensure_ascii=False)

        print(f"Podaci su uspesno sacuvani: {filepath}")

    except requests.exceptions.RequestException as e:
        print(f"Greska prilikom pozivanja API-ja: {e}")

fetch_openmeteo()     