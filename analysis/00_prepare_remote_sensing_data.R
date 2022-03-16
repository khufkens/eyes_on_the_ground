# formats data and stores data in
# a temporary location for further
# processing

library(tidyverse)
source("R/collect_gee_data.R")
source("R/collect_tamsat_arc_data.R")
source("R/site_details.R")

# get sites to process
site_details(site_list = TRUE, path = tempdir())
sites <- readRDS(file.path(tempdir(), "site_list.rds"))

# grab TAMSAT data
tamsat <- collect_tamsat_arc_data(
  sites,
  source = "/scratch/LACUNA/remote_sensing/TAMSAT/"
  )

saveRDS(
  tamsat,
  file = "/scratch/LACUNA/remote_sensing/tamsat_data.rds",
  compress = "xz"
  )

# grab ARC data
arc <- collect_tamsat_arc_data(
  sites,
  source = "/scratch/LACUNA/remote_sensing/ARC/"
)

saveRDS(
  arc,
  file = "/scratch/LACUNA/remote_sensing/arc_data.rds",
  compress = "xz"
  )

# download ERA5 and S2 data
gee <- collect_gee_data(df = sites)
 
saveRDS(
   gee,
   file = "/scratch/LACUNA/remote_sensing/gee_data.rds",
   compress = "xz"
)