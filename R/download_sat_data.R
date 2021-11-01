# Download ancillary remote sensing data from
# GEE

# make sure you have the gee_subset package
# installed for python, use:
#
# pip3 install gee-subset

# store output in the R temporary directory
directory = tempdir()

# read in meta-data

df <- read.csv()

df %>$
rowwise() %>%
do({
  # make the gee_subset.py python call
  # time the duration of the call for reporting
  system(sprintf("python3 data_extractor/data_extractor.py -lat %s -lon %s -s %s -e %s -d %s",
                lat,
                lon,
                start_date,
                end_date,
                directory
  ), wait = TRUE)
  end = Sys.time()

  # read in the data stored in the temporary directory
  df = read.table( paste0( directory, "/site_",
  tail( unlist( strsplit( product, "[/]" ) ), n=1 ), "_gee_subset.csv" ), sep = ",", header = TRUE, stringsAsFactors = FALSE)

  location <- c(.$lon, .$lat)

  # extract values from TAMSAT
  tamsat <- raster::stack(list.files("...", "*.tif", full.names = TRUE))
  tamsat_values <- raster::extract(tamsat, location)

  # extract values from ARC
  arc <- raster::stack(list.files("...", "*.nc", full.names = TRUE))
  arc_values <- raster::extract(arc, location)

})
