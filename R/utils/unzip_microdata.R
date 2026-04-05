#tests/testthat/test-unzip.R

#' @description Unzip the microdata for the 2025 school census
#' @param input_zip The path to the ZIP file
#' @param output_dir The directory to save the unzipped data
#' @return The output directory
unzip_microdata <- function(zip_path, dest_dir) {

  file_name <- fs::path_file(zip_path)
  message_sucess <- glue::glue("✅ {file_name} unzipped successfully!")

  if (missing(zip_path)) {
    stop(glue::glue("\n❌ Please provide the path to the ZIP {file_name}\n"))
  } else if (missing(dest_dir)) {
    stop(glue::glue("\n❌ Please provide the path to the output directory {dest_dir}\n"))
  }

  if (length(fs::dir_ls(dirname(zip_path))) > 0) {
    message(paste0("\n", message_sucess, "\n"))
    return(invisible(dest_dir))
  }

  utils::unzip(zip_path, exdir = dest_dir)
  file.remove(zip_path)
  
  message(message_sucess)
  return(invisible(dest_dir))
}