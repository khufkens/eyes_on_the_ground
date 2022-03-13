# write ancillary data to file
# in a json format ready for
# STAC integration
# 
# Linkages are maded outside
# of R using a python toolkit

library(tidyverse)
source("R/site_details.R")

# save site list, with exact coordinates
site_details(path = "/scratch/LACUNA", site_list = TRUE)

# get sites to process
sites <- site_details()
sites <- sites %>%
  # filter(
  #   season != "LR2021"
  # ) %>%
  select(
    farmer_unique_id,
    site_id,
    crop_name,
    sowing_date,
    expected_yield,
    season,
    spatial_location,
    spatial_unit,
    plot_size_acres,
    soil_type,
    cropping_system,
    drainage_type,
    sampled_area,
    moisture_content,
    lr2018_production,
    lr2019_production,
    lr2020_production,
    lr2021_production
  ) %>%
  mutate(
    site_name = paste(farmer_unique_id, site_id)
  )

# this routine returns errors because the
# do() call expects a dataframe output
# not data written to file, this can be
# safely ignored
sites %>%
  select(
    -site_name
  ) %>%
  group_by(farmer_unique_id, site_id) %>%
  do({
    
    filename_site_info <- paste(
      .$farmer_unique_id[1],
      .$site_id[1],
      "site_info.json",
      sep = "_"
    )
    
    filename_site_info <- file.path(
      "/scratch/LACUNA/staging_data/ancillary_data/site_info",
      filename_site_info)
    
    if(!file.exists(filename_site_info)){
      jsonlite::write_json(
        .,
        path = filename_site_info,
        pretty = FALSE
      )  
    }
  })

# merge all remote sensing data into one data frame
# and limit data to December 2021
df <- readRDS("/scratch/LACUNA/remote_sensing/gee_data.rds")
tamsat <- readRDS("/scratch/LACUNA/remote_sensing/tamsat_data.rds")
arc <- readRDS("/scratch/LACUNA/remote_sensing/arc_data.rds")

df <- bind_rows(df, tamsat)
df <- bind_rows(df, arc)
rm(list = c("arc","tamsat"))
gc()

df <- df %>%
  filter(
    date < as.Date("2021-06-01")
  )

df %>%
  group_by(farmer_unique_id, site_id, product) %>%
  do({
    
    site_name <- paste(.$farmer_unique_id[1], .$site_id[1])
    
    if(any(site_name == sites$site_name)) {
      
      if (grepl("ERA",.$product[1])){

        filename <- paste(
          .$farmer_unique_id[1],
          .$site_id[1],
          "ERA5.json",
          sep = "_"
        )

        jsonlite::write_json(
          .,
          path = file.path("/scratch/LACUNA/data_product/ancillary_data/era5", filename),
          pretty = FALSE
        )
      } else if (grepl("S2_R",.$product[1])) {

        filename <- paste(
          .$farmer_unique_id[1],
          .$site_id[1],
          "S2_R.json",
          sep = "_"
        )

        jsonlite::write_json(
          .,
          path = file.path("/scratch/LACUNA/data_product/ancillary_data/sentinel", filename),
          pretty = FALSE
        )
      } else if (grepl("S1_GRD",.$product[1])) {

        filename <- paste(
          .$farmer_unique_id[1],
          .$site_id[1],
          "S2_R.json",
          sep = "_"
        )

        jsonlite::write_json(
          .,
          path = file.path("/scratch/LACUNA/data_product/ancillary_data/sentinel", filename),
          pretty = FALSE
        )
      } else if (grepl("TAMSAT",.$product[1])) {

        filename <- paste(
          .$farmer_unique_id[1],
          .$site_id[1],
          "TAMSAT.json",
          sep = "_"
        )

        jsonlite::write_json(
          .,
          path = file.path("/scratch/LACUNA/data_product/ancillary_data/tamsat", filename),
          pretty = FALSE
        )
      } else if (grepl("ARC",.$product[1])) {

        filename <- paste(
          .$farmer_unique_id[1],
          .$site_id[1],
          "ARC.json",
          sep = "_"
        )

        jsonlite::write_json(
          .,
          path = file.path("/scratch/LACUNA/data_product/ancillary_data/arc", filename),
          pretty = FALSE
        )
      }
    }
  })
