#!/usr/bin/env python

# import libraries
import pystac
import os, re
from datetime import datetime
import pandas as pd
import argparse
import json
import geojson

# 1. read in the generated overview files
# which includes all required fields to
# populate the stac items (generated in R - should move to python)

# use pandas data frames
df = pd.read_csv("/scratch/LACUNA/data_product/meta-data/site_specifications.csv")
df = df[0:20]

# 2. loop over all rows of the pandas
# data frame and populate the STAC
# items.

# empty list to store STAC items
stac_items = []

for index, row in df.iterrows():

    left = 10
    bottom = 0
    right = 20
    top = 10

    # set general bounding box
    bbox = [left, bottom, right, top]
    
    # grab time, format correctly
    time_acquired = datetime.strptime(row['created_on'], '%d/%m/%Y')
    
    # Create geojson feature
    geom = geojson.Polygon([
        [left, bottom],
        [left, top],
        [right, top],
        [right, bottom]
    ])
    
    # Instantiate pystac item
    item = pystac.Item(
                id= str(row["site_id"]),
                geometry=geom,
                bbox=bbox,
                datetime = time_acquired,
                properties={
                })

    # fill the item with data (links)
    item.add_asset(
            key='analytic',
            asset=pystac.Asset(
                href=row['image_path'],
                title= "3 band RGB",
                # indicate it is a cloud optimized geotiff
                media_type=pystac.MediaType.JPEG,
                roles=([
                "analytic"
                ])
            )
    ) 
    
    stac_items.append(item)

# create containing catalog
catalog = pystac.Catalog(
    id='sample-catalog',
    description='Simple STAC catalog.'
    )

#for index, item in enumerate(stac_items):
#    catalog.add_item(item[0])

catalog.add_items(stac_items)

print(list(catalog.get_all_items()))
print(catalog.describe())