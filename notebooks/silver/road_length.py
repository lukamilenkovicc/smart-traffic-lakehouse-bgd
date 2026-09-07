
from geopy.distance import geodesic
from pyspark.sql.types import DoubleType
from pyspark.sql.functions import udf

def calculate_road_length(coordinates):
    if not coordinates or len(coordinates) < 2:
        return None
    
    total_distance = 0

    for i in range(len(coordinates) - 1):
        point_1 = (coordinates[i]["latitude"], coordinates[i]["longitude"])
        point_2 = (coordinates[i+1]["latitude"], coordinates[i+1]["longitude"])
        total_distance = total_distance + geodesic(point_1,point_2).km

    return round(total_distance,3)

        

calculate_road_length_udf = udf(calculate_road_length, DoubleType())



