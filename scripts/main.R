source("R/packages.R")

downloader <- new.env()
select_data <- new.env()

sys.source("R/utils/downloader.R", envir = downloader)
sys.source("R/utils/select_data.R", envir = select_data)

