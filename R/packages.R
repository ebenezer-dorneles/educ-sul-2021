pkgs <- c(
  "httr2", "readr", "dplyr", "ggplot2", "tidyr",
  "stringr", "dotenv", "geobr", "cli", "fs",
  "purrr", "data.table", "readxl", "duckdb",
  "DBI", "here", "glue"
)

to_install <- pkgs[!pkgs %in% rownames(installed.packages())]

if (length(to_install) > 0) {
  suppressMessages(
    suppressWarnings(
      install.packages(
        to_install,
        dependencies = TRUE,
        quiet = TRUE
      )
    )
  )
}
