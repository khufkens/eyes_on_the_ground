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

collect_gee_data <- function(
  df,
  source = "/scratch/LACUNA/remote_sensing/",
  dest = "/scratch/LACUNA/data_product/remote_sensing_data/"
) {
  
  # Download ancillary remote sensing data from
  # GEE
  
  # make sure you have the gee_subset package
  # installed for python, use:
  #
  # pip3 install gee-subset
  
  output <- df %>%
    rowwise() %>%
    do({

      filename_gee <- file.path(
        dest,
        .$farmer_unique_id,
        .$site_id,
        paste0(.$farmer_unique_id,"_",.$site_id, ".csv")
      )
      
      if(!file.exists(filename_gee)){
      # don't overload queries
      Sys.sleep(3)
        
      # make the gee_subset.py python call
      # time the duration of the call for reporting
      system(
        sprintf(
          "python3 python/data_extractor/data_extractor.py -lat %s -lon %s -s %s -e %s -d %s",
          .$lat,
          .$lon,
          .$start_date,
          .$end_date,
          tempdir()
        ),
        wait = TRUE
      )

      # read in the data stored in the temporary source this data comes
      # in a long format (stacked by product) and has a single pixel location
      # for now
      df <- read.table(
        file.path(tempdir(), "lacuna_gee_subset.csv"),
          sep = ",", header = TRUE, stringsAsFactors = FALSE)
      
      # reformat date field
      # time is not required
      df <- df %>%
        mutate(
          date = as.Date(date)
        )
      
      dir.create(
        file.path(
          dest,
          .$farmer_unique_id,
          .$site_id
        ),
          recursive = TRUE,
          showWarnings = FALSE
        )
      
      write.table(
        df,
        filename_gee,
        quote = FALSE,
        col.names = TRUE,
        sep = ","
      )
      
      # purge file
      try(file.remove(file.path(tempdir(), "lacuna_gee_subset.csv")))
      
      df$farmer_unique_id <- .$farmer_unique_id
      df$site_id <- .$site_id
      
      } else {
      
        df <- read.table(
          filename_gee,
          header = TRUE,
          sep = ","
        )
        
        df$farmer_unique_id <- .$farmer_unique_id
        df$site_id <- .$site_id
      }
      
      # data frame as output
      df
    })
  
  return(output)
}

