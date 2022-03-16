
#' Collect site details
#' 
#' Function to process ancillary data
#' into a tidy data frame, this includes
#' soil types, yields etc.
#'
#' @param site_list 
#' @param path 
#'
#' @return
#' @export

site_details <- function(
  site_list = FALSE,
  path
){
  # load libraries + scripts
  require(tidyverse)
  require(rnaturalearth)
  require(sf)
  source("R/extract_spatial_info.R")
  source("R/process_crop_cuts.R")
  
  # get crop cut data
  df <- process_crop_cuts()
  df <- df %>%
    mutate(
      site_id = as.numeric(site_id)
    ) %>%
    select(
      -crop_type
    )
  
  # Read in site details from excel sheets
  # these paths are hardcoded due to the irregular nature of the file
  # names. Will not change for provenance tracking reasons
  site_details_sr <- readxl::read_xlsx("/backup/see_it_grow/SR2020/Reports/SR2020_SiteDetails_3-5-2021.xlsx")
  site_details_lr <- readxl::read_xlsx("/backup/see_it_grow/LR2020/Reports/LR2020_SiteDetails_2021-05-03T04_47_08.770Z.xlsx")
  site_details_lr21 <- readxl::read_xlsx("/backup/see_it_grow/LR2021/Reports/SeeItGrow_LR2021.xlsx", sheet = "SiteDetails")
  
  # convert column names
  
  # fix underscores
  site_details_sr <- site_details_sr %>%
    rename_all(~ tolower(.)) %>%
    rename_all(~ gsub(" ", "_", .)) %>%
    mutate(
      expected_yield = as.numeric(expected_yield)
    )
  
  site_details_lr <- site_details_lr %>%
    rename_all(~ tolower(.)) %>%
    rename_all(~ gsub(" ", "_", .))
  
  site_details_lr21 <- site_details_lr21 %>%
    rename_all(~ tolower(.)) %>%
    rename_all(~ gsub(" ", "_", .)) %>%
    mutate(
      expected_yield = as.numeric(expected_yield)
    )
  
  # fix date fields
  site_details_sr <- site_details_sr %>%
    mutate(
      crop_name = tolower(crop_name),
      across(contains("date"), .fns = as.Date),
      across(contains("created"), .fns = as.Date)
    )
  
  site_details_lr <- site_details_lr %>%
    mutate(
      crop_name = tolower(crop_name),
      across(contains("date"), .fns = as.Date),
      across(contains("created"), .fns = as.Date)
    )
  
  site_details_lr21 <- site_details_lr21 %>%
    mutate(
      crop_name = tolower(crop_name),
      across(contains("date"), .fns = as.Date),
      across(contains("created"), .fns = as.Date)
    )
  
  # subset all data, retaining only relevant fields
  site_details_sr <- site_details_sr %>%
    select(
      farmer_unique_id,
      site_id,
      crop_name,
      sowing_date,
      expected_yield,
      latitude,
      longitude,
      createdon,
      seasoncode,
      initial_image_path,
      approve_comment
    )
  
  site_details_lr <- site_details_lr %>%
    select(
      farmer_unique_id,
      site_id,
      crop_name,
      sowing_date,
      expected_yield,
      latitude,
      longitude,
      createddate,
      initial_imagepath,
      approve_comment
    ) %>%
    mutate(
      seasoncode = "LR2020",
      createdon = createddate
    ) %>%
    rename(
      initial_image_path = initial_imagepath
    )
  
  site_details_lr21 <- site_details_lr21 %>%
    select(
      farmer_unique_id,
      site_id,
      crop_name,
      sowing_date,
      expected_yield,
      latitude,
      longitude,
      createdon,
      seasoncode,
      initial_image_path,
      approve_comment
    )
  
  # fix dates and column names
  site_details <- bind_rows(site_details_sr, site_details_lr)
  site_details <- bind_rows(site_details, site_details_lr21) %>%
    filter(
      !is.na(farmer_unique_id)
    ) %>%
    mutate(
      crop_name = ifelse(
        crop_name == "green grams",
        "green gram",
        crop_name
      ),
      crop_name = ifelse(
        crop_name == "beans",
        "soybean",
        crop_name
      )
    ) %>%
    rename(
      lon = longitude,
      lat = latitude,
      season = seasoncode,
      filename = initial_image_path,
      date = createdon
    ) %>%
    mutate(
      lat = as.numeric(lat),
      lon = as.numeric(lon),
      lat_orig = lat,
      lon_orig = lon,
      filename = basename(filename)
    ) %>%
    filter(
      lat < 7 # filter demo values etc
    )
  
  # privacy screening on coordinates
  # downsample using administrative boundaries
  site_details <- pbi_map_gadm(
    site_details,
    country = "KEN"
  )
  
  # merge general site details with crop cutting data
  site_details <- left_join(site_details, df)
  
  # write a file containing the original coordinates
  # and a date range to use for extraction of
  # remote sensing data
  
  if(site_list && !missing(path)){
    # write to file
    saveRDS(
      site_details %>%
        select(-lon, -lat) %>%
        rename(
          lat = lat_orig,
          lon = lon_orig
        ) %>%
        mutate(
          start_date = "2020-01-01",
          end_date = "2021-12-31"
        ),
      file.path(path,"site_list.rds")
    )  
  }
  
  return(site_details)
}

