import os
import json
import requests
from datetime import datetime as datum, timezone
from dotenv import load_dotenv

load_dotenv()
OPENAQ_API_KEY = os.getenv("OPENAQ_API_KEY")

OUTPUT_DIR = "/Volumes/bg_traffic/bg_traffic_bronze/landing/openaq"

LATITUDE = 44.8125
LONGITUDE = 20.4612
RADIUS_METERS = 25000 


def fetch_openaq():
    if not OPENAQ_API_KEY:
        print("OPENAQ API KEY nije pronadjen u .env fajlu!")
        return

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    timestamp_str = datum.now().strftime("%Y-%m-%d_%H%M%S")
    date_now = datum.now(timezone.utc).isoformat()
    url = f"https://api.openaq.org/v3/locations?coordinates={LATITUDE},{LONGITUDE}&radius={RADIUS_METERS}&limit=100"
    
    headers = {
        "X-API-Key": OPENAQ_API_KEY,
        "Accept": "application/json"
    }

    try:
        response = requests.get(url, headers=headers, timeout=15)
        response.raise_for_status()

        payload = {
            "source": "openaq-belgrade",
            "fetched_at": date_now,
            "request_url": url,
            "data": response.json()
        }

        filepath = f"{OUTPUT_DIR}/openaq_{timestamp_str}.json"
        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(payload, f, indent=2, ensure_ascii=False)
        print(f"Uspesno sacuvani OpenAQ podaci u: {filepath}")

    except requests.exceptions.RequestException as e:
        print(f"Greska prilikom pozivanja OpenAQ API-ja: {e}")
        if getattr(e, "response", None) is not None:
            print(f"Status: {e.response.status_code}")
            print(f"Poruka: {e.response.text}")


fetch_openaq()