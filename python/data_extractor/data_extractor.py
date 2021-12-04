#!/usr/bin/env python
# import libraries
import os, re
from datetime import datetime
import pandas as pd
import ee
import os, argparse
from gee_subset import gee_subset

# initiate GEE session
ee.Initialize()

# argument parser
def getArgs():

   parser = argparse.ArgumentParser(
    description = '''
    Downloads ancillary remote sensing data to complement PBI picture
    series. Data returned does not include geographic information,
    bookkeeping on site names etc should therefore be
    done outside this routine / program.
    ''',
    epilog = '''post bug reports to the github repository''')
    
   parser.add_argument('-lat',
                       '--latitude',
                       help = 'latitude of a site') 
    
   parser.add_argument('-lon',
                       '--longitude',
                       help = 'longitude of a site')

   parser.add_argument('-s',
                       '--start_date',
                       help = 'start date from which to collect data')

   parser.add_argument('-e',
                       '--end_date',
                       help = 'end date until which to collect data')


   parser.add_argument('-d',
                       '--directory',
                       help = 'location where to store the output data',
                       default = '.')

   parser.add_argument('-f',
                       '--filename',
                       help = 'filename prefix',
                       default = 'lacuna')

   return parser.parse_args()

def data_extractor(
              start_date = None,
              end_date = None,
              latitude = None,
              longitude = None,
              scale = 10
              ):

        # create empty pandas data frame to hold all data
        # from all products
        df = pd.DataFrame()

        # Download key products to supplement PBI images
        # these include data from the Sentinel programme,
        # the MODIS suite of products and matching climatological records 
        
        # Sentinel-2 MultiSpectral Instrument (MSI) Level-2A
        S2 = gee_subset.gee_subset(
         product = "COPERNICUS/S2_SR",
         bands = ["B1", "B2", "B3", "B4", "B8", "AOT", "SCL", "QA60"],
         start_date = start_date,
         end_date = end_date,
         latitude = latitude,
         longitude = longitude,
         scale = scale)
        
        # convert from semi-wide to simplified long format
        # drop the lat / lon values only retain date band and value
        # refer to documentation for multipliers
        S2 = pd.melt(
            S2,
            id_vars = ["date","product"],
            value_vars = ["B1", "B2", "B3", "B4", "B8", "AOT", "SCL", "QA60"],
            var_name = "band",
            value_name = "value")

        # append S2 data
        df = df.append(S2)
        
        # Sentinel-1 SAR GRD
        # C-band Synthetic Aperture Radar Ground Range Detected, log scaling
        # single band queries only!

        bands = ['VH','VV']

        for band in bands:

            S1 = gee_subset.gee_subset(
            product = "COPERNICUS/S1_GRD",
            bands = band,
            instrument = "IW",
            orbit = "ASCENDING",
            start_date = start_date,
            end_date = end_date,
            latitude = latitude,
            longitude = longitude,
            scale = scale)

            # convert to long format        
            S1 = pd.melt(
                S1,
                id_vars = ["date","product"],
                value_vars = band,
                var_name = "band",
                value_name = "value")

            # append S1 data
            df = df.append(S1)


        # too much data loop over products
        bands = [
            "surface_pressure",
            "mean_2m_air_temperature",
            "minimum_2m_air_temperature",
            "maximum_2m_air_temperature",
            "dewpoint_2m_temperature",
            "total_precipitation",
            "surface_pressure",
            "mean_sea_level_pressure",
            "u_component_of_wind_10m",
            "v_component_of_wind_10m"
            ]

        for band in bands:
   
            # ERA5 daily aggregates
            # climate reanalysis data
            ERA5 = gee_subset.gee_subset(
            product = "ECMWF/ERA5/DAILY",
            bands = [band],
            start_date = start_date,
            end_date = end_date,
            latitude = latitude,
            longitude = longitude,
            scale = scale)

            ERA5 = pd.melt(
                    ERA5,
                    id_vars = ["date","product"],
                    value_vars = band,
                    var_name = "band",
                    value_name = "value")

            # append ERA data
            df = df.append(ERA5)

        #print(ERA5)
        return(df)
        
if __name__ == '__main__':

    # parse arguments
    args = getArgs()

    # test download
    # non functioning for now
    out_data = data_extractor(
     start_date = args.start_date,
     end_date = args.end_date,
     latitude = float(args.latitude),
     longitude = float(args.longitude),
    )

    # write stuff to a file in directory
    # or just print to console   
    if args.directory:
        out_data.to_csv(args.directory +
         "/" + args.filename + "_gee_subset.csv", index = False)
    else:
        print(out_data)
