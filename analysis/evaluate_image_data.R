# read images lists and meta-data
# only retain 'accepted' images
# as screened by supervisors

# load in libraries
library(tidyverse)
source("analysis/homogenize_site_details.R")

# only retain site details
# wrt the filename, unique id and site id
site_details <- site_details %>%
  select(
    farmer_unique_id,
    site_id,
    filename,
    date,
    approve_comment
  ) %>%
  rename(
    farmer_id = farmer_unique_id
  ) %>%
  filter(
    grepl('accepted', approve_comment)
  ) %>%
  select(
    -approve_comment
  )

# base path
path <- "/backup/see_it_grow"

# read in site data
images_sr <- readxl::read_xlsx(
  file.path(path, "/SR2020/Reports/SR2020_RepeatPicturesDetails_3-5-2021.xlsx")
  )

images_lr <- readxl::read_xlsx(
  file.path(path, "LR2020/Reports/LR2020_Repeat_Picture_Details_2021-05-03T05_01_10.410Z.xlsx")
  )

images_lr21 <- readxl::read_xlsx(
  file.path(path, "LR2021/Reports/SeeItGrow_LR2021.xlsx"),
  sheet = "RepeatPictureDetails"
  )

# load site details (as it contains the first image filenames)

# rename columns
images_sr <- images_sr %>%
  rename(
    farmer_id = "Farmer Unique ID",
    site_id = "Site Id",
    date = "CreatedOn",
    filename = "Image"
  ) %>%
  filter(
    grepl('accepted',`Approve Comment`)
  ) %>%
  select(
    farmer_id,
    site_id,
    date,
    filename
  ) %>%
  mutate(
    date = as.Date(date),
    season = "SR2020"
  )

images_lr <- images_lr %>%
  rename(
    farmer_id = "Farmer Unique Code",
    site_id = "Site Id",
    date = "Repeat CreatedOn",
    filename = "Image"
  ) %>%
  filter(
    grepl('accepted',`Approve Comment`)
  ) %>%
  select(
    farmer_id,
    site_id,
    date,
    filename
  ) %>%
  mutate(
    date = as.Date(date),
    season = "LR2020"
  )

images_lr21 <- images_lr21 %>%
  rename(
    farmer_id = "Farmer Unique ID",
    site_id = "Site Id",
    date = "CreatedOn",
    filename = "Image"
  ) %>%
  filter(
    grepl('accepted',`Approve Comment`)
  ) %>%
  select(
    farmer_id,
    site_id,
    date,
    filename
  ) %>%
  mutate(
    date = as.Date(date),
    season = "LR2021"
  )

# bind files
images <- bind_rows(images_sr, images_lr)
images <- bind_rows(images, images_lr21)
images <- bind_rows(images, site_details)

# get date range
images <- images %>%
  group_by(farmer_id, site_id, ) %>%
  mutate(
    first_image = min(date),
    last_image = max(date)
  )

# add manual screening labels
manual_sr <- read_csv("data/ml_labels/manual/ACRE_SR_final_csv.csv")
manual_lr <- read_csv("data/ml_labels/manual/ACRE_LR_final_csv.csv")
manual <- bind_rows(manual_sr, manual_lr) %>%
  rename_all(~ tolower(.)) %>%
  rename(
    growth_stage = stage
  ) %>%
  select(
    filename,
    growth_stage,
    damage,
    extent
  )

# merge manual labels
images <- left_join(images, manual)

# merge machine learning labels
source("analysis/combine_ml_labels.R")
images <- left_join(images, df, by = "filename")

# subset only 2020 seasons
images <- images %>%
  filter(season != "LR2021")



