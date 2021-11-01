library(tidyverse)

# read in site data
images_sr <- readr::read_csv("/backup/see_it_grow/SR2020/Reports/SR2020_RepeatPicturesDetails_3-5-2021.csv")
images_lr <- readr::read_csv("/backup/see_it_grow/LR2020/Reports/LR2020_Repeat_Picture_Details_2021-05-03T05_01_10.410Z.csv")
images <- bind_rows(images_sr, images_lr)


# Add ML labels disturbances

drought <- read_csv("ml_labels/DR_NoDR_Results.csv") |>
  rename(
    'filename' = 'Old_name',
    'drought_prob' = 'Drought',
    'drought_model' = 'Model'
  ) |>
  select(-New_name, -No_Drought, -'...1')

images <- left_join(images, drought, by = 'filename')

growth <- read_csv("ml_labels/Growth_Stage_Results.csv") |>
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

drought_ext <- read_csv("ml_labels/Drought_Extent_results.csv") |>
  rename(
    'filename' = 'Old_name',
    'drought_extent_prob' = 'Extent',
    'drought_extent_model' = 'Model'
  ) |>
  select(-New_name, -'...1')

images <- left_join(images, drought_ext, by = 'filename')

multi <- read_csv("ml_labels/Multiclasss_Classification_results.csv") |>
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

