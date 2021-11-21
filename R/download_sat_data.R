#' Collect point based satellite
#' 
#' Give a data frame with coordinates
#' this routine collects all data ancillary
#' satellite data for ML model development.
#' This includes various vegetation indices,
#' meteo data, etc.
#'
#' @param df a data frame with coordinates
#' @param source a source where to download and or source data from
#' @param dest where to store the final results (by default results) are
#'  also returned to the workspace
#'
#' @return a
#' @export

download_sat_data <- function(
  df,
  source = tempdir(),
  dest
) {
  
  # Download ancillary remote sensing data from
  # GEE
  
  # make sure you have the gee_subset package
  # installed for python, use:
  #
  # pip3 install gee-subset
  
  df %>%
    rowwise() %>%
    do({
      # make the gee_subset.py python call
      # time the duration of the call for reporting
      system(sprintf("python3 data_extractor/data_extractor.py -lat %s -lon %s -s %s -e %s -d %s",
                     lat,
                     lon,
                     start_date,
                     end_date,
                     source
      ), wait = TRUE)
      end = Sys.time()
      
      # read in the data stored in the temporary source
      df = read.table( paste0(source, "/site_",
                               tail( unlist( strsplit( product, "[/]" ) ), n=1 ), "_gee_subset.csv" ), sep = ",", header = TRUE, stringsAsFactors = FALSE)
      
      location <- c(.$lon, .$lat)
      
      # extract values from TAMSAT
      tamsat <- raster::stack(list.files("...", "*.tif", full.names = TRUE))
      tamsat_values <- raster::extract(tamsat, location)
      
      # extract values from ARC
      arc <- raster::stack(list.files("...", "*.nc", full.names = TRUE))
      arc_values <- raster::extract(arc, location)
      
    })
  
  return(df)
  
}
