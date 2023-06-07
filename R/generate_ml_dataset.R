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

image_list <- image_list |>
  ungroup() |>
  select(
    filename,
    growth_stage,
    damage,
    extent,
    season
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

# create training data
train <- image_list |>
  group_by(damage, extent) |>
  sample_frac(0.75) |>
  ungroup()

# create testing hold-out
test_reference <- anti_join(
  image_list,
  train,
  by = "filename"
  ) 

test_candidates <- test_reference |>
  select(
    -growth_stage,
    -damage,
    -extent
  )

write.table(
  train,
  file = "data/train.csv",
  sep = ",",
  quote = FALSE,
  row.names = FALSE,
  col.names = TRUE
)

write.table(
  test_candidates,
  file = "data/test_candidates.csv",
  sep = ",",
  quote = FALSE,
  row.names = FALSE,
  col.names = TRUE
)

write.table(
  test_reference,
  file = "data/test_reference.csv",
  sep = ",",
  quote = FALSE,
  row.names = FALSE,
  col.names = TRUE
)



# summaries by season
# for the training data
train |>
  group_by(season) |>
  summarize(
    n()
  ) |> 
  print()

train |>
  group_by(damage) |>
  summarize(
    n()
  ) |> 
  print()

test |>
  group_by(damage,extent) |>
  summarize(
    n()
  )

