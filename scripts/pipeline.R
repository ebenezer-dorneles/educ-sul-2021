clean_environment <- function() {
  remove(list = ls())
  gc()
}

MSG_STAGE_0 <- "[START] Installing dependencies\n"
MSG_STAGE_1 <- "[STAGE 1] Setting up the environment\n"
MSG_STAGE_2 <- "[STAGE 2] Downloading the microdata\n"
MSG_STAGE_3 <- "[STAGE 3] Unzipping the microdata\n"
MSG_STAGE_4 <- "[STAGE 4] Data cleaning\n"
MSG_STAGE_5 <- "[STAGE 5] Creating the database\n"
MSG_STAGE_6 <- "[STAGE 6] Pipeline completed successfully!"



cli::cli_h1(MSG_STAGE_0)
# =============================================================================
# 0. PACKAGES
# =============================================================================
tryCatch({
  source("R/packages.R")
  message("\n✅ Packages loaded successfully!\n")
}, error = function(e) {
  message(paste0("\n❌ Failed to load packages: ", e$message, "\n"))
  stop(e)
})


cli::cli_h2(MSG_STAGE_1)
# =============================================================================
# 1. SETUP
# =============================================================================

dotenv::load_dot_env()
tryCatch({

  source("R/utils/download_microdata.R")
  source("R/utils/unzip_microdata.R")
  source("R/utils/clean_microdata_saeb_2023.R")
  source("R/utils/database.R")


  UFS_SUL <- c("41", "42", "43")

  ANO_SAEB   <- 2023

  DIR_ROOT    <- here::here()
  DIR_RAW     <- fs::path(DIR_ROOT, "data", "raw")
  DIR_INTERIM <- fs::path(DIR_ROOT, "data", "interim")
  DIR_DB      <- fs::path(DIR_ROOT, "data", "db")

  fs::dir_create(c(DIR_RAW, DIR_INTERIM, DIR_DB))
  fs::dir_create(fs::path(DIR_RAW, c("saeb")))

  DB_PATH <- fs::path(DIR_DB, glue::glue("saeb_sul_{ANO_SAEB}.duckdb"))
  message("\n✅ Setup completed successfully!\n")
}, error = function(e) {
  message(paste0("\n❌ Failed to setup: ", e$message, "\n"))
  stop(e)
})

cli::cli_h2(MSG_STAGE_2)
# =============================================================================
# 2. DOWNLOAD DOS ARQUIVOS BRUTOS
# =============================================================================

URL_SAEB <- glue::glue(Sys.getenv("LINK_SAEB_2023"))
ZIP_SAEB <- fs::path(DIR_RAW, "saeb", glue::glue("saeb_{ANO_SAEB}.zip"))

download_microdata(URL_SAEB, ZIP_SAEB, time_limit = 3000)

cli::cli_h2(MSG_STAGE_3)
# =============================================================================
# 3. EXTRAÇÃO
# =============================================================================

DIR_SAEB_EXTRAIDO <- fs::path(DIR_RAW, "saeb", as.character(ANO_SAEB))
fs::dir_create(DIR_SAEB_EXTRAIDO)

unzip_microdata(ZIP_SAEB, DIR_SAEB_EXTRAIDO)

cli::cli_h2(MSG_STAGE_4)
# =============================================================================
# 4. LIMPEZA DOS DADOS
# =============================================================================

if (!file.exists(DB_PATH)) {
  ESCOLAS <- clean_escolas(
    DIR_SAEB_EXTRAIDO,
    UFS_SUL,
    ANO_SAEB
  )

  PROFESSORES <- clean_professores(
    DIR_SAEB_EXTRAIDO,
    UFS_SUL,
    ANO_SAEB
  )

  ALUNOS <- clean_alunos(
    DIR_SAEB_EXTRAIDO,
    UFS_SUL,
    ANO_SAEB
  )
} else {
  message("\n✅ Data cleaning already completed!\n")
}

cli::cli_h2(MSG_STAGE_5)
# =============================================================================
# 5. CREATING THE DATABASE
# =============================================================================

if (!file.exists(DB_PATH)) {
  con <- DBI::dbConnect(duckdb::duckdb(), DB_PATH)

  save_table(con, ESCOLAS, "escolas", "ID_ESCOLA")
  save_table(con, PROFESSORES, "professores", "ID_ESCOLA")
  save_table(con, ALUNOS, "alunos", "ID_ESCOLA")
} else {
  message("\n✅ Database already exists!\n")
}


cli::cli_h1(glue::glue("{MSG_STAGE_6} Database saved in {DB_PATH}"))
# =============================================================================
# 6. CLEANING THE ENVIRONMENT
# =============================================================================
message("\nCleaning the environment... \n")
tables <- c("PROFESSORES", "ESCOLAS", "ALUNOS")
remove(tables)
gc()
