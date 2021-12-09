library(tidyverse)

source("R/generate_image_list.R")
source("R/site_details.R")

images <- generate_image_list()

images <- images %>%
  rename(
    farmer_unique_id = farmer_id
  )

site_info <- site_details() %>%
  select(
    -lat_orig,
    -lon_orig,
    -lat,
    -lon,
    -createddate,
    -filename,
    -approve_comment,
    -date
  )

# image list for stac formatting
write.table(
  site_info,
  "/scratch/LACUNA/staging_data/site_info.csv",
  row.names = FALSE,
  quote = FALSE,
  col.names = TRUE,
  sep = ","
)

site_info <- site_info %>%
  select(
    farmer_unique_id,
    site_id,
    crop_name,
    xmin,xmax,
    ymin,ymax
  )

images <- left_join(images, site_info)

# image list for stac formatting
write.table(
  images,
  "/scratch/LACUNA/staging_data/image_list.csv",
  row.names = FALSE,
  quote = FALSE,
  col.names = TRUE,
  sep = ","
)

# list all files
files <- list.files(
  "/scratch/LACUNA/staging_data/images/","*.jpg|*.JPG",
  recursive = TRUE,
  full.names = TRUE)

files <- data.frame(file_path = files)
files <- files %>%
  mutate(
    filename = basename(file_path)
  )

# merge with images
images <- left_join(images, files)

# remove those with no corresponding image files
images <- images %>%
  filter(
    !is.na(file_path)
  )

images %>%
  rowwise() %>%
  do({
    
    img_file <- file.path(
      "/scratch/LACUNA/data_product/images/", .$filename)
    
    # json filename
    json_file <- paste0(tools::file_path_sans_ext(.$filename),".json")
    
    # copy image file to destination
    file.copy(
      .$file_path,
      img_file
    )
    
    # remove some extra data
    x <- as.data.frame(.)
    x <- x %>%
      select(
        -first_image,
        -last_image,
        -xmin, -xmax, -ymin, -ymax,
        -file_path
      )
    
    # write json label file
    jsonlite::write_json(
      x,
      path = file.path("/scratch/LACUNA/data_product/labels/", json_file),
      pretty = FALSE
    )
  })

message("Do visual screening of data !!")
message("Update image list afterwards")