library(downloader)
library(readr)
library(dotenv)

#' Download and extract the microdata for the 2025 school census
#' This function checks if the data has already been downloaded and extracted. 
#' If not, it downloads the ZIP file from the specified URL, extracts its 
#' contents to the "data/raw/" directory, and then removes the ZIP file.
download_microdata <- function() {
  load_dot_env()
  message_sucess <- "✅ Data downloaded and extracted successfully! Let's start analyzing! 🚀"
  url_download <- Sys.getenv("LINK_CENSO_EDUC_2025")
  
  dir <- "data/raw/"
  file_name <- "censo_escolar_2025.zip"

  if (! dir.exists(dir)) dir.create(dir, showWarnings = FALSE)
  
  files = paste0(dir, "microdados_censo_escolar_2025", "/dados/")
  if (list.files(files) %>% length() > 0) {
    message(message_sucess)
    return(invisible(NULL))
  }
  
  options(timeout = 600)
  download(url_download,
           destfile = paste0(dir, file_name),
           mode = "wb")
  
  unzip(paste0(dir, file_name), exdir = dir)
  file.remove(paste0(dir, file_name))
  
  message(message_sucess)
  return(invisible(NULL))
}
