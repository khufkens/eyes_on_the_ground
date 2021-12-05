# cleanup of the ml labels
library(tidyverse)

files <- list.files("data/ml_labels/ml/","*Predictions.csv", full.names = TRUE)

dr <- read.table(files[1], header = TRUE, sep = ",")
dr_ext <- read.table(files[2], header = TRUE, sep = ",")
gs <- read.table(files[3], header = TRUE, sep = ",")
mc <- read.table(files[4], header = TRUE, sep = ",")

df <- bind_cols(dr, dr_ext, gs, mc)

df <- df %>%
  rename(
    filename = "name...2"
  ) %>%
  mutate(
    filename = basename(filename),
    extent = round(extent*100)
  ) %>%
  select(
    -starts_with("X"),
    -starts_with("name"),
    -no_drought
    )

# rename stuff to not conflict with other labels
df <- df %>%
  rename(
    drought_probability = drought,
    drought_extent = extent,
    growth_sowing = sowing,
    growth_vegetative = vegetative,
    growth_flowering = flowering,
    growth_maturity = maturity,
    disturbance_none = good,
    disturbance_weeds = weed,
    disturbance_drought = drought_conditions,
    disturbance_nutrient_deficit = nutrient_deficiency
  )
