source("R/packages.R")

download <- new.env()
data_censo_2025 <- new.env()

sys.source("R/download.R", envir = download)
sys.source("R/data.R", envir = data_censo_2025)

download$download_microdata()


