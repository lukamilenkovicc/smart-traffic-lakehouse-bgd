import os
import json
import requests
from datetime import datetime as datum


LATITUDE = 44.8125
LONGITUDE = 20.4612

OUTPUT_DIR = os.path.join("data","raw","openmeteo")


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
            "fetched_at": datum.utcnow().isoformat(),
            "request_url": URL,
            "data": data,
        }

        timestamp_str = datum.now().strftime("%Y-%m-%d_%H%M%S")
        filename = f"openmeteo_{timestamp_str}.json"
        filepath = os.path.join(OUTPUT_DIR, filename)




        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(payload, f, indent=2, ensure_ascii=False)

        print(f"Podaci su uspesno sacuvani: {filepath}")

    except requests.exceptions.RequestException as e:
        print(f"Greska prilikom pozivanja API-ja: {e}")

if __name__ == "__main__":
    fetch_openmeteo()     