#' Collect point based satellite
#' 
#' Give a data frame with coordinates
#' this routine collects all data ancillary
#' satellite data for ML model development.
#' This includes various vegetation indices,
#' meteo data, etc. Only repos on GEE are evaluated
#'
#' @param df a data frame with coordinates
#' @param source a source where to download and or source data from
#' @param dest where to store the final results (by default results) are
#'  also returned to the workspace
#'
#' @return a
#' @export

collect_tamsat_arc_data <- function(
  df,
  source = "/scratch/LACUNA/remote_sensing/TAMSAT/",
  dest = "/scratch/LACUNA/data_product/remote_sensing_data/"
) {
  
  location <- df %>%
    dplyr::select(
      lon,
      lat
    )

  files <- list.files(
    source,
    "*",
    full.names = TRUE,
    recursive = TRUE
  )
  
  data <- lapply(
    files,
    function(file){
    
    # extract values from TAMSAT
    r <- raster::brick(file, varname = "rfe")
    r_values <- raster::extract(r, location)[,1]
    
    if(tools::file_ext(file) == "nc"){
      r_dates <- as.Date(
        names(r),
        format = "X%Y.%m.%d"
      )  
      product <- "TAMSAT"
    } else {
      r_dates <- as.Date(
        names(r),
        format = "africa_arc.%Y%m%d"
      )
      product <- "ARC"
    }
    
    return(
      data.frame(
        farmer_unique_id = df$farmer_unique_id,
        site_id = df$site_id,
        date = r_dates,
        product = product,
        value = r_values
      )
    )
  })
  
  data <- do.call("rbind", data)
  
  return(data)
}

