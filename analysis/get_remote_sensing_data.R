# required libraries
library(tidyverse)
source("R/collect_tamsat_arc_data.R")
source("R/collect_gee_data.R")

# load site list
df <- readr::read_csv("/scratch/LACUNA/remote_sensing/site_list.csv")

# download or subset all data
data <- collect_gee_data(
  df,
  dest = "/scratch/LACUNA/data_product/remote_sensing_data/"
)

saveRDS(data, file = "/scratch/LACUNA/remote_sensing/gee_data.rds")

# download or subset all data
data <- collect_tamsat_arc_data(
  df,
  source = "/scratch/LACUNA/remote_sensing/TAMSAT/",
  dest = "/scratch/LACUNA/data_product/remote_sensing_data/" 
)

saveRDS(data, file = "/scratch/LACUNA/remote_sensing/tamsat_data.rds")

# download or subset all data
data <- collect_tamsat_arc_data(
  df,
  source = "/scratch/LACUNA/remote_sensing/ARC/",
  dest = "/scratch/LACUNA/data_product/remote_sensing_data/" 
)

saveRDS(data, file = "/scratch/LACUNA/remote_sensing/arc_data.rds")

# read data

