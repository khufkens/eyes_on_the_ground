library(dplyr)

files <- jsonlite::read_json("ancillary_assets_missing.json") |>
  unlist()

files <- data.frame(file = files) |>
  dplyr::mutate(
    file = gsub(".json", ".zip", file)
  )

# list ancillary zip files
zip_files <- list.files(
  "ancillary_data/",
  "*.zip",
  recursive = TRUE,
  full.names = TRUE
  )

files <- files |>
  rowwise() |>
  mutate(
    location = ifelse(any(grepl(file, zip_files)), grep(file, zip_files), NA)
  )

files <- files |>
  rowwise() |>
  mutate(
    file_remove = zip_files[location]
  )

file.remove(as.vector(files$file_remove))

