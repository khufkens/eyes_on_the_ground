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

base_path = "https://raw.githubusercontent.com/khufkens/EotG_data_final/main/"

# 1. read in the generated overview files
# which includes all required fields to
# populate the stac items (generated in R - should move to python)

# use pandas data frames
df = pd.read_csv("/scratch/LACUNA/data_product/image_list.csv")

# 2. extract and set some of the overall catalog details, this includes
# a title and an elaborate description, as well as temporal and 
# spatial extent as extracted from the image data frame above

title_cat = '''Eyes on the Ground'''

description_cat = '''
The "Eyes on the Ground" project ([lacunafund.org](https://lacunafund.org/ag2020awards/))
is a collaboration between ACRE Africa, the International Food Policy Research Institute (IFPRI),
and the Lacuna Fund, to create a large machine learning (ML) dataset of smallholder farmer's
fields based upon previous work within the Picture Based Insurance framework
(Ceballos, Kramer and Robles, 2019, [https://doi.org/10.1016/j.deveng.2019.100042](https://doi.org/10.1016/j.deveng.2019.100042)).
This is a unique dataset of georeferenced crop images along with labels on input use,
crop management, phenology, crop damage, and yields, collected across 8 counties in Kenya.
The research leading to this dataset was undertaken as part of the CGIAR research program on Policies,
Institutions and Markets (PIM).
'''

df.date = pd.to_datetime(df.date)

start_date = min(df.date)
end_date = max(df.date)

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
                        "url": "https://lacunafund.org/"
                        },
                        {
                        "name": "International Food Policy Research Institute",
                        "roles": ["producer","processor"],
                        "url": "http://ifpri.org"
                        },
                        {
                        "name": "CGIAR research program on Policies, Institutions and Markets (PIM)",
                        "roles": ["producer"],
                        "url": "https://pim.cgiar.org/"
                        },
                        {
                        "name": "BlueGreen Labs (bv)",
                        "roles": ["processor"],
                        "url": "http://bluegreenlabs.org"
                        },
                    ]
        }
    )

title_cat_image = '''Eyes on the Ground Image data'''

description_cat_image = '''
 Picture based insurance images, sorted by administrative region
 '''

image_catalog = pystac.Catalog(
    id = 'EotG_images',
    title = title_cat_image,
    description = description_cat_image,
    extra_fields = {
        "license" : "CC-BY-SA-4.0",
        "extent": catalog_extent.to_dict(),
        "providers": [
                        {
                        "name": "LACUNA fund",
                        "roles": ["producer","processor"],
                        "url": "https://lacunafund.org/"
                        },
                        {
                        "name": "International Food Policy Research Institute",
                        "roles": ["producer","processor"],
                        "url": "http://ifpri.org"
                        },
                        {
                        "name": "CGIAR research program on Policies, Institutions and Markets (PIM)",
                        "roles": ["producer"],
                        "url": "https://pim.cgiar.org/"
                        },
                        {
                        "name": "BlueGreen Labs (bv)",
                        "roles": ["processor"],
                        "url": "http://bluegreenlabs.org"
                        },
                    ]
        }
    )
    
# define collection
image_collection = pystac.Collection(
    id = "image_collection",
    description = 'image data',
    extent = catalog_extent,
    keywords = ['machine learning','crop monitoring','validation','remote sensing'],
    license = 'CC-BY-SA-4.0'
)

grouped_obj = df.groupby(["spatial_location"])
for key, subset in grouped_obj:
    print("Key is: " + str(key))

    # set collection id
    collection_id = str(key)

    # get extent
    left = min(subset['xmin'])
    bottom = min(subset['ymin'])
    right = max(subset['xmax'])
    top = max(subset['ymax'])

    # set general bounding box
    bbox_subset = [left, bottom, right, top]

    # start and end dates
    start_date = min(subset.date)
    end_date = max(subset.date)

    # convert extents
    spatial_extent = pystac.SpatialExtent([bbox_subset])
    temporal_extent = pystac.TemporalExtent([[start_date, end_date]])
    collection_extent = pystac.Extent(spatial_extent, temporal_extent)

    # define collection
    collection = pystac.Collection(
        id = collection_id,
        description = 'image data',
        extent = collection_extent,
        keywords = ['machine learning','crop monitoring','validation','remote sensing'],
        license = 'CC-BY-SA-4.0'
    )

    # 3. loop over all rows of the pandas
    # data frame and populate the STAC
    # items.

    # empty list to store STAC items
    stac_items = []

    for index, row in subset.iterrows():

        left = row['xmin']
        bottom = row['ymin']
        right = row['xmax']
        top = row['ymax']

        # set general bounding box
        bbox = [left, bottom, right, top]
        
        # grab time, format correctly
        time_acquired = row.date

        # unique image id based on unique filename
        id = "img_" + os.path.splitext(row.filename)[0]
 
        # need to make this a function at some point
        # get extreme bounds
        left = row['xmin']
        bottom = row['ymin']
        right = row['xmax']
        top = row['ymax']
    
        # formulate in array
        coordinates = [[
            [left, bottom],
            [left, top],
            [right, top],
            [right, bottom],
            [left, bottom]
        ]]

        # return values
        geom =  {'type': 'Polygon', 'coordinates': coordinates}

        # format image path relative to the stack index
        image_link = base_path + "images/" + row.filename
        thumb_link = base_path + "thumbs/" + row.filename
        label_link = base_path + "labels/" + os.path.splitext(row.filename)[0] + ".json"
        era5_link = base_path + "ancillary_data/era5/" + row.farmer_unique_id + "_" + str(row.site_id) + "_ERA5.zip"
        sentinel_link = base_path + "/ancillary_data/sentinel/" + row.farmer_unique_id + "_" + str(row.site_id) + "_S2_R.zip"
        tamsat_link = base_path + "/ancillary_data/tamsat/" + row.farmer_unique_id + "_" + str(row.site_id) + "_TAMSAT.zip"
        arc_link = base_path + "/ancillary_data/arc/" + row.farmer_unique_id + "_" + str(row.site_id) + "_ARC.zip"
        
        # validate links, skip if missing
        # but report to console for further checks
        

        # read in site meta data which will be provided in
        # the properties tag
        f = open("/scratch/LACUNA/data_product/" + "ancillary_data/site_info/" +
             row.farmer_unique_id + "_" + str(row.site_id) + "_site_info.json")
        metadata = json.load(f)[0]
        f.close()

        # Instantiate pystac item
        item = pystac.Item(
                    id = id,
                    geometry = geom,
                    bbox = bbox,
                    datetime = time_acquired,
                    collection = collection_id,
                    properties = metadata
                    )

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
                    href = label_link,
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
                key = 'sentinel',
                asset = pystac.Asset(
                    href = sentinel_link,
                    title= "Sentinel remote sensing data",
                    media_type = "application/zip",
                    roles = ([
                    "data"
                    ])
                )
        )

        # link to the site based meta-data
        item.add_asset(
                key = 'ERA5',
                asset = pystac.Asset(
                    href = era5_link,
                    title= "ERA5 climate data",
                    media_type = "application/zip",
                    roles = ([
                    "data"
                    ])
                )
        )

        # link to the site based meta-data
        item.add_asset(
                key = 'ARC',
                asset = pystac.Asset(
                    href = arc_link,
                    title= "ARC precipitation estimates",
                    media_type = "application/zip",
                    roles = ([
                    "data"
                    ])
                )
        )

        # link to the site based meta-data
        item.add_asset(
                key = 'TAMSAT',
                asset = pystac.Asset(
                    href = tamsat_link,
                    title= "TAMSAT precipitation estimates",
                    media_type = "application/zip",
                    roles = ([
                    "data"
                    ])
                )
        )

        # append item to stac item list
        # for this iteration
        stac_items.append(item)

    # add all items to the collection
    collection.add_items(stac_items)
    
    # add stuff to catalog and write to disk
    #image_catalog.add_child(collection)
    image_catalog.add_child(collection)

catalog.add_child(image_catalog)
#catalog.set_self_href("https://raw.githubusercontent.com/khufkens/eyes_on_the_ground/main/")
#catalog.make_all_asset_hrefs_relative()
catalog.normalize_hrefs("https://raw.githubusercontent.com/khufkens/EotG_data_final/main")

# describe and validate
catalog.describe()
catalog.validate_all()

# save
catalog.save(
    catalog_type = pystac.CatalogType.RELATIVE_PUBLISHED
    )
