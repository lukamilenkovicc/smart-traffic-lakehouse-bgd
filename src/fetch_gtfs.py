import io
import os
import zipfile
import requests
from datetime import datetime as datum

GTFS_URL = "https://data.gov.rs/sr/datasets/r/729be9a1-7ed9-453d-9a3d-68fa30f07529"
BASE_OUTPUT_DIR = "/Volumes/bg_traffic/bg_traffic_bronze/landing/gtfs"

def fetch_gtfs():
    today_str = datum.now().strftime("%Y-%m-%d")
    output_dir = f"{BASE_OUTPUT_DIR}/{today_str}"
    os.makedirs(output_dir, exist_ok=True)
    try:
        response = requests.get(GTFS_URL, timeout = 30)
        response.raise_for_status()

        with zipfile.ZipFile(io.BytesIO(response.content)) as z:
            z.extractall(output_dir)

        print(f"GTFS podaci su uspesno preuzeti, nalaze se u {output_dir}")
        print(f"Sadrzaj foldera: ", os.listdir(output_dir))

    except requests.exceptions.RequestException as e:
        print("Greska prilikom preuzimanja GTFS fajla: ")
        if getattr(e, "response", None) is not None:
            print(f"Status: {e.response.status_code}")
            print(f"Poruka: {e.response.text}")
        else:
            print(e)

    except zipfile.BadZipFile:
        print("Preuzeti fajl nije validan zip fajl")


