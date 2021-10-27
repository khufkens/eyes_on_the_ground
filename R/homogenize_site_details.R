# Homogenize field campaign data
library(tidyverse)
library(rnaturalearth)
library(sf)

source("R/extract_spatial_info.R")

# read in districts
district <- sf::st_read("data/kedistrictboundaries/ke_district_boundaries.shp")

# read in site details
site_details_sr <- readr::read_csv("/backup/see_it_grow/SR2020/Reports/SR2020_SiteDetails_3-5-2021.csv")
site_details_lr <- readr::read_csv("/backup/see_it_grow/LR2020/Reports/LR2020_SiteDetails_2021-05-03T04_47_08.770Z.csv")
site_details <- bind_rows(site_details_sr, site_details_lr) %>%
  filter(
    lat < 7 # filter demo values etc
  ) %>%
  arrange(
    farmer_id
  ) %>%
  select(
    -farmer_name
  )

# privacy screening on coordinates
 
# downsample using administrative boundaries
site_details_gadm <- pbi_map_gadm(
  site_details,
  country = "KEN"
)

# downsampled using grid based approach
site_details_grid <- pbi_map_grid(
  site_details
)

# save stuff TODO