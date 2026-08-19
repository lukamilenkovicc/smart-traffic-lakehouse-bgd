## Ingestion Layer

Ovaj sloj je odgovoran za prikupljanje sirovih (raw) podataka sa spoljnih API servisa i web izvora, kao i za njihovo skladištenje u JSON formatu unutar `data/raw/` direktorijuma pre daljeg procesiranja u Medallion arhitekturi (Bronze sloj).

### Izvori podataka i skripte

* **`ingestion/fetch_tomtom.py`**: Povlači podatke o trenutnom protoku saobraćaja (*Traffic Flow*) za ključne saobraćajnice i mostove u Beogradu, kao i trenutne saobraćajne incidente (*Traffic Incidents*). Podaci se čuvaju u `data/raw/tomtom/`.
* **`ingestion/fetch_openmeteo.py`**: Povlači trenutne vremenske uslove i prognozu (temperatura, padavine, vidljivost) sa Open-Meteo API-ja za područje Beograda. Podaci se čuvaju u `data/raw/openmeteo/`.
* **`ingestion/fetch_gtfs.py`**: Prikuplja podatke o radovima na putu, izmenama u linijama gradskog prevoza i zastojima sa javnih servisa. Podaci se čuvaju u `data/raw/gtfs/`.

---

### Podešavanje i Pokretanje

1. **Instalacija zavisnosti:**
   ```bash
   pip install -r requirements.txt