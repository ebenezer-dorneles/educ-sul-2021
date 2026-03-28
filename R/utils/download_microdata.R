library(dotenv)
library(downloader)

#' Download the microdata
#' @param url_download The URL of the microdata
#' @param output_dir The directory to save the microdata
#' @return The output directory
download_microdata <- function(url_download, output_dir) {
  load_dot_env()
  message_sucess <- "✅ Data downloaded and extracted successfully! Let's start analyzing! 🚀"

  if (dir.exists(output_dir)) {
    message(message_sucess)
    return(invisible(NULL))
  } else {
    dir.create(output_dir, showWarnings = FALSE) 
  }

  options(timeout = 600)
  download(url_download,
           destfile = paste0(output_dir, file_name),
           mode = "wb")
  
  message(message_sucess)
  return(invisible(output_dir))
}