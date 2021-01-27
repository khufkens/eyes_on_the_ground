import os, re
from datetime import datetime
import pandas as pd
import ee
ee.Initialize()

#import sys
#sys.path.append(r"../..")
from gee_subset import gee_subset

def data_extractor(
              start_date = None,
              end_date = None,
              latitude = None,
              longitude = None,
              scale = 10
              ):

        # Download key products to supplement PBI images
        # these include data from the Sentinel programme,
        # the MODIS suite of products and matching climatological records 
        
        # Sentinel-2 MultiSpectral Instrument (MSI) Level-2A
        S2 = gee_subset(
         product = "COPERNICUS/S2_SR",
         bands = ["B1", "B2", "B2", "B4", "B8", "AOT", "SCL", "QA60"],
         start_date = start_date,
         end_date = end_date,
         latitude = latitude,
         longitude = longitude,
         scale = scale)
        
        print(S2)
        
        # Sentinel-1 SAR GRD
        # C-band Synthetic Aperture Radar Ground Range Detected, log scaling
        S1 = gee_subset(
         product = "COPERNICUS/S1_GRD",
         bands = ["HH", "HV", "VV", "VH", "angle"],
         start_date = start_date,
         end_date = end_date,
         latitude = latitude,
         longitude = longitude,
         scale = scale)
         
        print(S1)
        
        # MODIS MCD15A3H (C6)
        # Leaf Area Index/FPAR 4-Day Global 500m
        MCD15A3H = gee_subset(
         product = "MODIS/006/MCD15A3H",
         bands = ["Fpar", "Lai", "FparExtra_QC"],
         start_date = start_date,
         end_date = end_date,
         latitude = latitude,
         longitude = longitude,
         scale = scale)
         
        print(MCD15A3H)
         
        # ERA5 daily aggregates
        # climate reanalysis data
        ERA5 = gee_subset(
         product = "ECMWF/ERA5/DAILY",
         bands = ["mean_2m_air_temperature",
                  "minimum_2m_air_temperature",
                  "maximum_2m_air_temperature",
                  "dewpoint_2m_air_temperature",
                  "total_precipitation",
                  "surface_pressure"
                  ],
         start_date = start_date,
         end_date = end_date,
         latitude = latitude,
         longitude = longitude,
         scale = scale)

        print(ERA5)

        # WORLDCLIM
        # monthly climatology
        WORLDCLIM = gee_subset(
         product = "WORLDCLIM/V1/MONTHLY",
         bands = ["tavg",
                  "tmin",
                  "tmax",
                  "precip"
                  ],
         start_date = start_date,
         end_date = end_date,
         latitude = latitude,
         longitude = longitude,
         scale = scale)
          
        print(WORLDCLIM)
        
if __name__ == '__main__':

    # test download
    # non functioning for now
    data_extractor(
     start_date = "2015-01-01",
     end_date = "2015-12-31",
     latitude = 44,
     longitude = -72,
    )
