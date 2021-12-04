# crop cut data of season 2021 comes
# in a tabbed excel, not ideal

library(tidyverse)
library(readxl)

# read in all sheets
df <- lapply(1:10, function(sheet){
  sh <-readxl::read_xlsx(
    "/backup/see_it_grow/LR2021/Reports/LR2021 CCE data sheet - PBI & IUK.xlsx",
    sheet = sheet
    )
  colnames(sh) <- tolower(names(sh))
  sh <- sh %>%
    mutate(
      across(.fns = as.character)
    ) %>%
    mutate(
      across(.fns = tolower)
    )
  return(sh)
})

# bind all sheets
df <- bind_rows(df)

# grab only the most relevant information
df <- df %>%
  filter(
    !is.na(`farmer unique id`)
  )
# convert all characters to lower caps
df <- df %>%
  mutate_if(is_character,tolower)

# fix underscores
df <- df %>%
  rename_all(~ gsub(" ", "_", .)) %>%
  select(
    -cropping_system
    )

# upper case farmer_id
df <- df %>%
  dplyr::mutate(
    farmer_unique_id = toupper(farmer_unique_id)
  )

# rename cropping system values
df <- df %>%
  rename(
    'cropping_system' = 'croping_system'
  ) %>%
  mutate(
    cropping_system = ifelse(
      cropping_system == "intercropping", 2, cropping_system),
    cropping_system = ifelse(
      cropping_system == "monocropping", 1, cropping_system),
    cropping_system = ifelse(
      cropping_system == "monocroppng", 1, cropping_system),
    cropping_system = ifelse(
      cropping_system == "mixed farming", 3, cropping_system)
  )

# rename GAP values
df <- df %>%
  mutate(
    level_of_gap = ifelse(level_of_gap == "poor", 1, level_of_gap),
    level_of_gap = ifelse(level_of_gap == "average", 2, level_of_gap),
    level_of_gap = ifelse(level_of_gap == "well observed", 3, level_of_gap)
  )

# final name fixes
df <- df %>%  
  rename(
    plot_size_acres = 'plot_size(acres)',
    sample_area_acres = 'sample_area_(acres)',
    dry_weight_kgs = 'dry_weight_(kgs)',
    total_production_kgs = 'total_production_(kgs)'
  )

# final data selection
df <- df %>%
  select(
    farmer_unique_id,
    site_id,
    plot_size_acres,
    soil_type,
    cropping_system,
    crop_type,
    drainage_type,
    sampled_area,
    moisture_content,
    lr2018_production,
    lr2019_production,
    lr2020_production,
    lr2021_production,
    dry_weight_kgs,
    total_production_kgs
  )
