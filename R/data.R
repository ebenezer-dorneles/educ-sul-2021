library(readr)
library(stringr)
library(dplyr)

#' List all available tables in the raw data directory
#' @return A character vector containing the names of all CSV files in the raw data directory
list_tables <- function() {
  data <- list.files("data/raw/microdados_censo_escolar_2025/dados")
  
  csv_files <- data[str_detect(data, "\\.csv$")]
  
  return(csv_files)
}

#' Get a table from the raw data
#' @param table_name The name of the table to be loaded (e.g., "escolas.csv")
#' @return A data frame containing the contents of the specified table
get_table <- function(table_name) {
  file_path <- paste0("data/raw/microdados_censo_escolar_2025/dados/", table_name)
  
  data <- read_delim(file_path, 
                     delim = ";",
                     escape_double = FALSE,
                     locale = locale(encoding = "ISO-8859-1"), 
                     trim_ws = TRUE)
  
  return(data)
}

#' Get a table from the raw data using a command-line interface
#' This function lists all available tables and prompts the user to select one 
#' by entering its corresponding number. It then loads and returns the selected 
#' table as a data frame.
get_table_by_cli <- function() {
  tables <- list_tables()
  
  cat("Available tables:\n")
  for (i in seq_along(tables)) {
    cat(i, ": ", tables[i], "\n", sep = "")
  }
  
  choice <- as.integer(readline(prompt = "Enter the number of the table you want to load: "))
  
  if (choice < 1 || choice > length(tables)) {
    stop("Invalid choice. Please enter a number between 1 and ", length(tables), ".")
  }
  
  selected_table <- tables[choice]
  return(get_table(selected_table))
}