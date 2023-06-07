
#' List all valid images
#' 
#' All valid images for processing, as
#' manually screened by surveyors
#'
#' @param path where to store the full list as csv file
#' @param out_path where to store the image list
#'
#' @return
#' @export

generate_image_list <- function(
  path = "/backup/see_it_grow",
  path_out = "/scratch/LACUNA/staging_data/",
  ml_labels = TRUE
) {
  
  # load in libraries
  require(tidyverse)
  source("R/site_details.R")
  source("R/ml_labels.R")
  
  # only retain site details
  # wrt the filename, unique id and site id
  site_info <- site_details(path = path) %>%
    select(
      farmer_unique_id,
      site_id,
      filename,
      date,
      season,
      approve_comment
    ) %>%
    rename(
      farmer_id = farmer_unique_id
    ) %>%
    filter(
      grepl('accepted', approve_comment)
    ) %>%
    select(
      -approve_comment
    ) %>%
    mutate(
      date = as.character(date)
    )

  # read in site data
  images_sr <- readxl::read_xlsx(
    file.path(path, "/SR2020/Reports/SR2020_RepeatPicturesDetails_3-5-2021.xlsx")
  )
  
  images_lr <- readxl::read_xlsx(
    file.path(path, "LR2020/Reports/LR2020_Repeat_Picture_Details_2021-05-03T05_01_10.410Z.xlsx")
  )
  
  images_lr21 <- readxl::read_xlsx(
    file.path(path, "LR2021/Reports/SeeItGrow_LR2021.xlsx"),
    sheet = "RepeatPictureDetails"
  )
  
  # load site details (as it contains the first image filenames)
  
  # rename columns
  images_sr <- images_sr %>%
    rename(
      farmer_id = "Farmer Unique ID",
      site_id = "Site Id",
      date = "CreatedOn",
      filename = "Image"
    ) %>%
    filter(
      grepl('accepted',`Approve Comment`)
    ) %>%
    select(
      farmer_id,
      site_id,
      date,
      filename
    ) %>%
    mutate(
      date = format(
        strptime(as.character(date), "%Y-%m-%d %H:%M:%S", tz = "EAT"),
        tz = "UTC"),
      season = "SR2020"
    )
  
  images_lr <- images_lr %>%
    rename(
      farmer_id = "Farmer Unique Code",
      site_id = "Site Id",
      date = "Repeat CreatedOn",
      filename = "Image"
    ) %>%
    filter(
      grepl('accepted',`Approve Comment`)
    ) %>%
    select(
      farmer_id,
      site_id,
      date,
      filename
    ) %>%
    mutate(
      date = format(
        strptime(as.character(date), "%Y-%m-%dT%H:%M:%S.000Z", tz = "UTC"),
        tz = "UTC"),
      season = "LR2020"
    )
  
  images_lr21 <- images_lr21 %>%
    rename(
      farmer_id = "Farmer Unique ID",
      site_id = "Site Id",
      date = "CreatedOn",
      filename = "Image"
    ) %>%
    filter(
      grepl('accepted',`Approve Comment`)
    ) %>%
    select(
      farmer_id,
      site_id,
      date,
      filename
    ) %>%
    mutate(
      date = format(
        strptime(as.character(date), "%Y-%m-%d %H:%M:%S", tz = "EAT"),
        tz = "UTC"),
      season = "LR2021"
    )
  
  # bind files
  images <- bind_rows(images_sr, images_lr)
  images <- bind_rows(images, images_lr21)
  images <- bind_rows(images, site_info)
  print(head(images))
  
  # get date range
  images <- images %>%
    group_by(farmer_id, site_id, ) %>%
    mutate(
      first_image = min(date),
      last_image = max(date)
    )
  
  print(nrow(images))
  
  # add manual screening labels
  manual_sr <- read_csv("data/ml_labels/manual/ACRE_SR_final_csv.csv")
  manual_lr <- read_csv("data/ml_labels/manual/ACRE_LR_final_csv.csv")
  manual_lr21 <- read_csv("data/ml_labels/manual/ACRE_LR21_final_csv.csv")
  
  manual <- bind_rows(manual_sr, manual_lr)
  manual <- bind_rows(manual, manual_lr21)
  manual <- manual %>%
    rename_all(~ tolower(.)) %>%
    rename(
      growth_stage = stage
    ) %>%
    select(
      filename,
      growth_stage,
      damage,
      extent
    ) %>%
    mutate(
      filename = basename(filename)
    )
  
  # merge manual labels
  images <- left_join(images, manual)
  
  # merge machine learning labels
  if(ml_labels){
    labels <- ml_labels()
    images <- left_join(images, labels, by = "filename")
  }
  
  print("writing to file")
  if(!missing(path_out)){
    # output data
    write.table(
      images,
      file.path(path_out, "image_list.csv"),
      col.names = TRUE,
      quote = FALSE,
      row.names = FALSE
    )
  } else {
    return(images)  
  }
}



