import os
import json
import requests
from datetime import datetime as datum, timezone
from dotenv import load_dotenv

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), ".env"))
TOMTOM_API_KEY = os.getenv("TOMTOM_API_KEY")
OUTPUT_DIR = os.path.join("data","raw","tomtom")

LOCATIONS = {
    "gazela":{"lat": 44.803612744238414, "lon": 20.44161311547014},
    "brankov_most": {"lat": 44.814944745538476,"lon": 20.447958195789756},
    "autokomanda": {"lat":44.79006243245153, "lon": 20.466817377312005},
    "kneza_milosa":{"lat":44.80847966999754, "lon": 20.46354776119058},
    "takovska":{"lat":44.81339202658573, "lon": 20.47209035160833},
    "savska":{"lat":44.8047975134633, "lon": 20.45323212172419},
    "ustanicka":{"lat":44.78422193631761, "lon": 20.518656933494537},
    "vojislava_ilica":{"lat":44.78441845023255, "lon": 20.50090008229649},
    "bulevar_kralja_aleksandra":{"lat":44.79547130093965, "lon": 20.499085411885314},
    "pancevacki_most":{"lat":44.820854574338924, "lon": 20.49002337080168},
    "most_na_adi":{"lat":44.79538287892638, "lon": 20.426360038115895},
    "jurija_gagarina":{"lat":44.803495332965284, "lon": 20.424133274769513},
    "omladinskih_brigada":{"lat":44.813854525731216, "lon": 20.403824566953453},
    "nemanjina":{"lat":44.80505059314264, "lon": 20.461394495789087},
    "bulevar_mihajla_pupina":{"lat":44.814824464936414, "lon": 20.434620039572152}

}


def fetch_traffic_flow(name, coords):
    url = (f"https://api.tomtom.com/traffic/services/4/flowSegmentData/relative/10/json"
    f"?key={TOMTOM_API_KEY}&point={coords['lat']},{coords['lon']}")
    response = requests.get(url, timeout=10)
    response.raise_for_status()
    return response.json(), url


def fetch_traffic_incidents():
    box = "20.35,44.72,20.58,44.88"
    url = (f"https://api.tomtom.com/traffic/services/5/incidentDetails"
           f"?key={TOMTOM_API_KEY}&bbox={box}&language=en-GB")
    response = requests.get(url, timeout = 10)
    response.raise_for_status()
    return response.json(), url


def fetch_tomtom():
    if not TOMTOM_API_KEY:
        print("TOMTOM API KEY nije pronadjen")
        return

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    timestamp_str = datum.now().strftime("%Y-%m-%d_%H%M%S")
    date_now = datum.now(timezone.utc).isoformat()

    try:
        flow_data = {}
        for name, coords in LOCATIONS.items():
            data, req_url = fetch_traffic_flow(name, coords)
            flow_data[name] = data

        payload_flow = {
            "source":"tomtom-traffic-flow",
            "fetched_at": date_now,
            "request_url": req_url,
            "data":flow_data
        }

        flow_filepath = os.path.join(OUTPUT_DIR, f"tomtom_flow_{timestamp_str}.json")
        with open(flow_filepath, "w", encoding = "utf-8") as f:
            json.dump(payload_flow, f, indent=2, ensure_ascii=False)
        print(f"Uspesno sacuvan protok saobracaja u: {flow_filepath}")

        incidents_data, inc_url = fetch_traffic_incidents()
        payload_incidents = {
            "source":"tomtom-traffic-incidents",
            "fetched_at": date_now,
            "request_url": inc_url,
            "data": incidents_data
        }

        inc_filepath = os.path.join(OUTPUT_DIR, f"tomtom_incidents_{timestamp_str}.json")
        with open(inc_filepath, "w", encoding="utf-8") as f:
            json.dump(payload_incidents, f, indent=2, ensure_ascii=False)
        print("Uspesno sacuvani podaci o saobracajnim incidentima")

    except requests.exceptions.RequestException as e:
        print("Greska prilikom pozivanja TomTom API-ja: ")
        if getattr(e, "response", None) is not None:
            print(f"Status: {e.response.status_code}")
            print(f"Poruka: {e.response.text}")
        else:
            print(e)

if __name__ == "__main__":
    fetch_tomtom()






    




