library(httr2)
library(fs)

#' @description Download the microdata
#' @param url The URL of the microdata
#' @param dest The directory to save the microdata
#' @return The output directory
download_microdata <- function(url, dest, time_limit = 600) {
  
  file_name <- fs::path_file(dest)
  message_sucess <- glue::glue("✅ {file_name} downloaded successfully!")

  dir_name <- dirname(dest)
  if (length(fs::dir_ls(dir_name)) > 0) {
    message(paste0("\n", message_sucess, "\n"))
    return(invisible(dest))
  } else {
    fs::dir_create(dir_name, showWarnings = FALSE) 
  }

  tryCatch({
    req <- httr2::request(url) |>
      httr2::req_options(ssl_verifypeer = FALSE) |>
      httr2::req_timeout(time_limit) |>
      httr2::req_retry(max_tries = 3)
    resp <- httr2::req_perform(req, path = dest)
    message(paste0("\n", message_sucess, "\n"))
    return(invisible(dest))
  }, error = function(e) {
    message(paste0("\n❌ Failed to download ", file_name, ": ", e$message, "\n"))
    stop(e)
  })
}