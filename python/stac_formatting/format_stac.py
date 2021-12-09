#!/usr/bin/env python

# import libraries
import pystac
from pystac import (Catalog, CatalogType, SpatialExtent, Extent)
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
df = pd.read_csv("/scratch/LACUNA/staging_data/image_list.csv")
df = df[0:100]

# 2. extract and set some of the overall catalog details, this includes
# a title and an elaborate description, as well as temporal and 
# spatial extent as extracted from the image data frame above

title_cat = '''Eyes on the Ground'''

description_cat = '''
 The 'Eyes on the Ground' project is a collaboration between IFPRI/CGIAR,
 the Lacuna Fund to create a large machine learning (ML) dataset of smallholder
 farmer's fields based upon previous work within the Picture Based Insurance 
 framework (Ceballos 2019).
 
 Data provided in this dataset is extensively labelled for machine learning and 
 modelling purposes. The provided labels include growth stage, damage, damage extent
 as well as matching ancillary remote sensing and climate data.
 '''

start_date = datetime.strptime(min(df['date']), '%Y-%m-%d')
end_date = datetime.strptime(max(df['date']), '%Y-%m-%d')

left = min(df['xmin'])
bottom = min(df['ymin'])
right = max(df['xmax'])
top = max(df['ymax'])

# set general bounding box
bbox_cat = [left, bottom, right, top]

# convert extents
spatial_extent = pystac.SpatialExtent([bbox_cat])
temporal_extent = pystac.TemporalExtent([[start_date, end_date]])
catalog_extent = pystac.Extent(spatial_extent, temporal_extent)


# create containing collection
collection_id = 'EotG_collection_v2'
collection = pystac.Collection(
    id = collection_id,
    description = 'image data',
    extent = pystac.SpatialExtent([[-180, -90, 180, 90]]),
    keywords = ['machine learning','crop monitoring','validation','remote sensing'],
    license = 'CC-BY-SA-4.0'
    )


# 3. loop over all rows of the pandas
# data frame and populate the STAC
# items.

# empty list to store STAC items
stac_items = []

for index, row in df.iterrows():

    left = row['xmin']
    bottom = row['ymin']
    right = row['xmax']
    top = row['ymax']

    # set general bounding box
    bbox = [left, bottom, right, top]
    
    # grab time, format correctly
    time_acquired = datetime.strptime(row['date'], '%Y-%m-%d')

    # unique image id based on unique filename
    id = "img_" + os.path.splitext(row['filename'])[0]
    
    # Create geojson feature
    geom = geojson.Polygon([
        [left, bottom],
        [left, top],
        [right, top],
        [right, bottom]
    ])

    # Instantiate pystac item
    item = pystac.Item(
                id = id,
                geometry = geom,
                bbox = bbox,
                datetime = time_acquired,
                collection = collection_id,
                properties = {}
                )

#"links": [
#  { "rel": "collection", "href": "link/to/collection/record.json" }
#]

    # format image path relative to the stack index
    image_link = "/images/" + row['filename']
    thumb_link = "/thumbs/" + row['filename']
    label_link = "/labels/" + os.path.splitext(row['filename'])[0] + ".json"
    metadata_link = "/ancillary_data/site_info/" + row['farmer_unique_id'] + "_" + str(row['site_id']) + "_site_info.json"

    # link to the image data
    item.add_asset(
            key = 'image',
            asset = pystac.Asset(
                href = image_link,
                title= "3 band RGB",
                media_type = pystac.MediaType.JPEG,
                roles = ([
                 "data"
                ])
            )
    ) 
    
    # link to the machine learning labels
    item.add_asset(
            key = 'label',
            asset = pystac.Asset(
                href = image_link,
                title= "ML labels",
                media_type = "application/json",
                roles = ([
                 "data"
                ])
            )
    )
    
    # link to the thumbnails
    item.add_asset(
            key = 'thumbnail',
            asset = pystac.Asset(
                href = thumb_link,
                title= "thumbnail",
                media_type = pystac.MediaType.JPEG,
                roles = ([
                 "thumbnail"
                ])
            )
    )

    # link to the site based meta-data
    item.add_asset(
            key = 'metadata',
            asset = pystac.Asset(
                href = metadata_link,
                title= "site meta-data",
                media_type = "application/json",
                roles = ([
                 "metadata"
                ])
            )
    )

    # append item to stac item list
    # for this iteration
    stac_items.append(item)

# add all items to the collection
collection.add_items(stac_items)

# create a base catalog to hold
# all collections / items
# fill with details as calculated
# at the start of ingestion of the data
catalog = pystac.Catalog(
    id = 'EotG_release_v1',
    title = title_cat,
    description = description_cat,
    extra_fields = {
        "license" : "CC-BY-SA-4.0",
        "extent": catalog_extent.to_dict(),
        "providers": [
                        {
                        "name": "LACUNA fund",
                        "roles": ["producer","processor"],
                        "description": "Our voice on data",
                        "url": "https://lacunafund.org/"
                        },
                        {
                        "name": "International Food Policy Research Institute",
                        "roles": ["producer","processor"],
                        "url": "http://ifpri.org"
                        },
                        {
                        "name": "BlueGreen Labs (bv)",
                        "roles": ["processor"],
                        "url": "http://bluegreenlabs.org"
                        },
                    ]
        }
    )
# add stuff to catalog and write to disk
catalog.add_child(collection)
catalog.describe()
catalog.normalize_hrefs('/scratch/LACUNA/data_product/')
#print(catalog.get_self_href())
#print(item.get_self_href())

catalog.save(
    catalog_type = pystac.CatalogType.SELF_CONTAINED
    )