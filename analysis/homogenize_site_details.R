# Homogenize field campaign data
library(tidyverse)
library(rnaturalearth)
library(sf)

source("R/extract_spatial_info.R")

# read in site details
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
    #createdon,
    seasoncode
    #initial_image_path,
    #approve_comment
  )

site_details_lr <- site_details_lr %>%
  select(
    farmer_unique_id,
    site_id,
    crop_name,
    sowing_date,
    expected_yield,
    latitude,
    longitude
    #createddate,
    #initial_imagepath,
    #approve_comment
  ) %>%
  mutate(
    seasoncode = "LR2020"
    #createdon = createddate
    #initial_image_path = initial_imagepath
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
    #createdon,
    seasoncode
    #initial_image_path,
    #approve_comment
  )

# fix dates and column names
site_details <- bind_rows(site_details_sr, site_details_lr)
site_details <- bind_rows(site_details, site_details_lr21) %>%
  filter(
    !is.na(farmer_unique_id)
  ) %>%
  mutate(
    crop_name = ifelse(crop_name == "green grams", "green gram", crop_name)
  ) %>%
  rename(
    lon = longitude,
    lat = latitude,
    season_code = seasoncode
  ) %>%
  mutate(
    lat = as.numeric(lat),
    lon = as.numeric(lon)
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

# visualize stuff
p <-ggplot(site_details) +
  geom_point(
    aes(
      lon,
      lat,
      colour = season_code
    )
  )

print(p)

# write to file
write.table(
  site_details,
  "/scratch/LACUNA/data_product/meta-data/site_specifications.csv",
  quote = FALSE,
  row.names = FALSE,
  col.names = TRUE,
  sep = ","
)
