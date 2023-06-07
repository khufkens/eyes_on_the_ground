# create Zindi ML challenge dataset
library(tidyverse)
source("R/generate_image_list.R")
source("R/site_details.R")
source("R/ml_labels.R")

# list all images
image_list <- generate_image_list(
  path = "../../data-raw/see_it_grow_original/",
  #path_out = "data/",
  ml_labels = TRUE
)

# only retain those with original labels
image_list <- image_list |>
  filter(
    !is.na(growth_stage)
  ) |>
  select(
    -first_image,
    -last_image,
    -date,
    -farmer_id,
    -site_id
  )

# read SR2021 data
sr2021 <- readxl::read_xlsx("../../data-raw/see_it_grow_original/SR2021/Reports/Final SR2021.xlsx") |>
  rename(
    "growth_stage" = "Growth Stage",
    "damage" = "Type of damage",
    "extent" = "Extent of damage"
  ) |>
  select(
    filename,
    growth_stage,
    damage,
    extent
  ) |>
  mutate(
    season = "SR2021"
  )

# combine both the old and new dataset
image_list <- bind_rows(
  image_list,
  sr2021
)
