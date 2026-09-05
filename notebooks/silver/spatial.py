import geopandas as gpd
from shapely.geometry import Point
from pyspark.sql.functions import udf
from pyspark.sql.types import StringType

municipalities = gpd.read_file(
    "/Volumes/bg_traffic/bg_traffic_silver/geo_podaci/beograd_opstine.geojson"
)

def get_municipality_name(lat, lon):

    if lat is None or lon is None:
        return "Unknown"
    
    point = Point(lon, lat)

    for _, row in municipalities.iterrows():

        if row["geometry"].covers(point):
            return row["Value_e"].replace("BEOGRAD-","")

    return "Unknown"


find_municipality_udf = udf(get_municipality_name, StringType())
