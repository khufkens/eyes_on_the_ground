library(tidyverse)

# read in site data
images_sr <- readxl::read_xlsx("/backup/see_it_grow/SR2020/Reports/SR2020_RepeatPicturesDetails_3-5-2021.xlsx")
images_lr <- readxl::read_xlsx("/backup/see_it_grow/LR2020/Reports/LR2020_Repeat_Picture_Details_2021-05-03T05_01_10.410Z.xlsx")
images_lr21 <- readxl::read_xlsx("/backup/see_it_grow/LR2021/Reports/SeeItGrow_LR2021.xlsx", sheet = "RepeatPictureDetails")

# rename columns
images_sr <- images_sr |>
  rename(
    farmer_id = "Farmer Unique ID",
    site_id = "Site Id",
    date = "CreatedOn",
    damage = "Damage Answer1",
    filename = "Image"
  ) %>%
  filter(
    grepl('accepted',`Approve Comment`)
  ) %>%
  select(
    farmer_id,
    site_id,
    date,
    damage,
    filename
  ) %>%
  mutate(
    date = as.Date(date)
  )

images_lr <- images_lr |>
  rename(
    farmer_id = "Farmer Unique Code",
    site_id = "Site Id",
    date = "Repeat CreatedOn",
    damage = "Damage Answer1",
    filename = "Image"
  ) %>%
  filter(
    grepl('accepted',`Approve Comment`)
  ) %>%
  select(
    farmer_id,
    site_id,
    date,
    damage,
    filename
  ) %>%
  mutate(
    date = as.Date(date)
  )

images_lr21 <- images_lr21 |>
  rename(
    farmer_id = "Farmer Unique ID",
    site_id = "Site Id",
    date = "CreatedOn",
    damage = "Damage Answer1",
    filename = "Image"
  ) %>%
  filter(
    grepl('accepted',`Approve Comment`)
  ) %>%
  select(
    farmer_id,
    site_id,
    date,
    damage,
    filename
  ) %>%
  mutate(
    date = as.Date(date)
  )

# bind files
images <- bind_rows(images_sr, images_lr)
images <- bind_rows(images, images_lr21)

# get date range
images <- images %>%
  mutate(
    first_image = min(date),
    last_image = max(date)
  )

# Add ML labels disturbances

drought <- read_csv("python/ml_labels/DR_NoDR_Results.csv") |>
  rename(
    'filename' = 'Old_name',
    'drought_prob' = 'Drought',
    'drought_model' = 'Model'
  ) |>
  select(-New_name, -No_Drought, -'...1')

images <- left_join(images, drought, by = 'filename')

growth <- read_csv("python/ml_labels/Growth_Stage_Results.csv") |>
  rename(
    'filename' = 'Old_name',
    'growth_sowing_prob' = 'Sowing',
    'growth_vegetative_prob' = 'Vegetative',
    'growth_flowering_prob' = 'Flowering',
    'growth_maturity_prob' = 'Maturity',
    'growth_model' = 'Model'
  ) |>
  select(-New_name, -'...1')

images <- left_join(images, growth, by = 'filename')

drought_ext <- read_csv("python/ml_labels/Drought_Extent_results.csv") |>
  rename(
    'filename' = 'Old_name',
    'drought_extent_prob' = 'Extent',
    'drought_extent_model' = 'Model'
  ) |>
  select(-New_name, -'...1')

images <- left_join(images, drought_ext, by = 'filename')

multi <- read_csv("python/ml_labels/Multiclasss_Classification_results.csv") |>
  rename(
    'filename' = 'Old_name',
    'multi_good_prob' = 'Good',
    'multi_weed_prob' = 'Weed',
    'multi_drought_prob' = 'Drought',
    'multi_nutrient_prob' = 'Nutri. Def.',
    'multi_model' = 'Model'
  ) |>
  select(-New_name, -'...1')

images <- left_join(images, multi, by = 'filename')

# add ML automatic screening (for reference)

