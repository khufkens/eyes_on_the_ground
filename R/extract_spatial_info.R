#' Maps locations to town centroids
#' 
#' For a particular country maps locations of fields to the
#' centroid of towns. This anonymizes the data by obfuscating
#' the original location.
#'
#' @param df data frame containing lat lon locations
#' @param country country to use in mapping locations to town centroids
#'
#' @return dataframe with lat lon values mapped to centroids
#' @export
#' 
pbi_map_gadm <- function(
  df,
  country
){
  # check for data frame
  if(missing(df)){
    stop("no data frame provided")
  }
  
  # checking country
  if(missing(country)){
    stop("please provide a GADM country abbreviation, e.g. IND for India")
  }
  
  # check for coordinates
  if(!any(grepl("lon",names(df)))){
    stop("missing lon")
  }
  
  # check for coordinates
  if(!any(grepl("lat",names(df)))){
    stop("missing lat")
  }
  
  # download GADM data
  gadm <- raster::getData('GADM',
                          country = country,
                          level=3,
                          path = tempdir())
  
  # convert coordinates to sp objects
  lat_lon <- raster::projection(gadm)
  location <- sp::SpatialPoints(cbind(df$lon,df$lat),
                                sp::CRS(lat_lon))
  
  # list centroid and cell values
  centroids <- data.frame(sp::coordinates(gadm),
                          cell_values = gadm@data$NAME_3)
  
  # find overlap between points and polygons
  attributes <- sp::over(location, gadm)
  attributes <- attributes[grepl("^NAME_*",names(attributes))]
  names(attributes) <- c("country","state","county","town")
  
  # merge with data frame and drop points without an overlap
  df <- data.frame(df,
                   spatial_location = attributes$town,
                   spatial_unit = "gadm",
                   stringsAsFactors = FALSE)
  df <- df[!is.na(df$spatial_location),]
  
  # map centroid coordinates to lat / lon
  # anonymization process
  for(i in 1:nrow(df)){
    df$lat[i] <- 
      centroids[centroids['cell_values'] == df[i,'spatial_location'], 2][1]
    df$lon[i] <- 
      centroids[centroids['cell_values'] == df[i,'spatial_location'], 1][1]
  }
  
  return(df)
}

#' Maps coordinates to grid centroids
#' 
#' Anonymizes lat/lon coordinates by remapping them
#' to low resolution grid cell centroids
#'
#' @param df data frame containing lat lon locations 
#' @param resolution resolution of the map in minutes (2.5, 5, 10)
#'
#' @return dataframe with lat lon values mapped to centroids
#' @export
#' 
pbi_map_grid <- function(
  df,
  resolution = 2.5
){
  # check for data frame
  if(missing(df)){
    stop("no data frame provided")
  }
  
  # check for coordinates
  if(!any(grepl("lon",names(df)))){
    stop("missing lon")
  }
  
  # check for coordinates
  if(!any(grepl("lat",names(df)))){
    stop("missing lat")
  }
  
  # download WorldClim data
  wc <- suppressMessages(raster::getData('worldclim',
                                         var = 'prec',
                                         res = resolution,
                                         path = tempdir())$prec1)
  
  # convert coordinates to sp objects
  lat_lon <- raster::projection(wc)
  
  # create sp object for field locations
  location <- sp::SpatialPoints(
    cbind(df$lon, df$lat),
    sp::CRS(lat_lon))
  
  cells <- 1:raster::ncell(wc$prec1)
  
  # fill with numeric values (row wise)
  wc[] <- cells
  
  # crop and convert to polygon
  wc <- raster::crop(wc,
                     sp::bbox(location),
                     snap = 'out')
  wc <- raster::rasterToPolygons(wc)
  
  # list centroid and cell values
  centroids <- data.frame(sp::coordinates(wc),
                          cell_values = wc@data$prec1)
  
  # find overlap between points and polygons
  attributes <- as.numeric(unlist(sp::over(location, wc)))
  
  # merge with data frame and drop points without an overlap
  df <- data.frame(df,
                   spatial_location = attributes,
                   spatial_unit = paste0("worldclim_",resolution),
                   stringsAsFactors = FALSE)
  df <- df[!is.na(df$spatial_location),]
  
  # map centroid coordinates to lat / lon
  # anonymization process
  for(i in 1:nrow(df)){
    df$lat[i] <- 
      centroids[centroids['cell_values'] == df[i,'spatial_location'], 2][1]
    df$lon[i] <- 
      centroids[centroids['cell_values'] == df[i,'spatial_location'], 1][1]
  }
  
  return(df)
}
