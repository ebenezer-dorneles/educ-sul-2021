#tests/testthat/test-unzip.R

#' Unzip the microdata for the 2025 school census
#' This function checks if the data has already been unzipped.
#' If not, it unzips the ZIP file from the specified URL to the "data/raw/" directory,
#' and then removes the ZIP file.
unzip_microdata <- function(input_zip, output_dir) {
  if (missing(input_zip)) {
    stop("Please provide the path to the ZIP file.")
  } else if (!file.exists(input_zip)) {
    stop("The ZIP file does not exist.")
  } else if (missing(output_dir)) {
    stop("Please provide the path to the output directory.")
  }

  message_sucess <- "✅ Data unzipped successfully! Let's start analyzing! 🚀"
  filename <- basename(input_zip)

  if (list.files(output_dir) %>% length() > 0) {
    message(message_sucess)
    return(invisible(NULL))
  }


  utils::unzip(input_zip, exdir = output_dir)
  file.remove(input_zip)
  
  message(message_sucess)
  return(invisible(output_dir))
}