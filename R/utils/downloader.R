source("R/utils/unzip.R")
source("R/utils/download_microdata.R")

library(downloader)
library(readr)
library(dotenv)
library(stringr)

#' Download and extract the microdata
#' This function checks if the data has already been downloaded and extracted. 
#' If not, it downloads the ZIP file from the specified URL, extracts its 
#' contents to the "data/raw/" directory, and then removes the ZIP file.
download_microdata <- function(link_microdata) {
  message_sucess <- "✅ Data downloaded and extracted successfully! Let's start analyzing! 🚀"
  dir <- "data/raw/"
  file_name <- "censo_escolar_2025.zip"

  download_microdata(link_microdata, dir)

  if (list.files(dir) %>% str_detect(".zip") %>% any()) {
    data_unzip <- unzip_microdata(paste0(dir, file_name), dir)
  }
  
  message(message_sucess)
  return(invisible(data_unzip))
}


