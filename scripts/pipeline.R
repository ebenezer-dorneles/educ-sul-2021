
cli::cli_h1("[START] Installing dependencies")
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


cli::cli_h2("[STAGE 1] Setting up the environment")
# =============================================================================
# 1. SETUP
# =============================================================================

dotenv::load_dot_env()
tryCatch({

  source("R/utils/download_microdata.R")
  source("R/utils/unzip_microdata.R")
  source("R/utils/clean_microdata_censo_escolar_2023.R")
  source("R/utils/database.R")


  UFS_SUL <- c("41", "42", "43")

  ANO_CENSO  <- 2023
  ANO_SAEB   <- 2023

  DIR_ROOT    <- here::here()
  DIR_RAW     <- fs::path(DIR_ROOT, "data", "raw")
  DIR_INTERIM <- fs::path(DIR_ROOT, "data", "interim")
  DIR_DB      <- fs::path(DIR_ROOT, "data", "db")

  fs::dir_create(c(DIR_RAW, DIR_INTERIM, DIR_DB))
  fs::dir_create(fs::path(DIR_RAW, c("censo_escolar", "saeb")))

  DB_PATH <- fs::path(DIR_DB, "educ_sul.duckdb")
  message("\n✅ Setup completed successfully!\n")
}, error = function(e) {
  message(paste0("\n❌ Failed to setup: ", e$message, "\n"))
  stop(e)
})

cli::cli_h2("[STAGE 2]: Downloading the microdata")
# =============================================================================
# 2. DOWNLOAD DOS ARQUIVOS BRUTOS
# =============================================================================

URL_CENSO <- glue::glue(Sys.getenv("LINK_CENSO_EDUC_2023"))
ZIP_CENSO  <- fs::path(DIR_RAW, "censo_escolar", glue::glue("censo_{ANO_CENSO}.zip"))

URL_SAEB <- glue::glue(Sys.getenv("LINK_SAEB_2023"))
ZIP_SAEB <- fs::path(DIR_RAW, "saeb", glue::glue("saeb_{ANO_SAEB}.zip"))

download_microdata(URL_CENSO, ZIP_CENSO)
download_microdata(URL_SAEB, ZIP_SAEB, time_limit = 3000)


cli::cli_h2("[STAGE 3]: Unzipping the microdata")
# =============================================================================
# 3. EXTRAÇÃO — CENSO ESCOLAR
# =============================================================================

DIR_CENSO_EXTRAIDO <- fs::path(DIR_RAW, "censo_escolar", as.character(ANO_CENSO))
fs::dir_create(DIR_CENSO_EXTRAIDO)

DIR_SAEB_EXTRAIDO <- fs::path(DIR_RAW, "saeb", as.character(ANO_SAEB))
fs::dir_create(DIR_SAEB_EXTRAIDO)

unzip_microdata(ZIP_CENSO, DIR_CENSO_EXTRAIDO)
unzip_microdata(ZIP_SAEB, DIR_SAEB_EXTRAIDO)


cli::cli_h2("[STAGE 4]: Cleaning the data")
# =============================================================================
# 4. LIMPEZA DOS DADOS
# =============================================================================

ESCOLAS <- clean_escolas(
  DIR_CENSO_EXTRAIDO,
  UFS_SUL,
  ANO_CENSO,
  force = TRUE
)

#PROFESSORES <- clean_professores(
#  DIR_SAEB_EXTRAIDO,
#  UFS_SUL,
#  ANO_SAEB,
#  DIR_INTERIM,
#  DB_PATH,
#  force = TRUE
#)
#
#ALUNOS <- clean_alunos(
#  DIR_SAEB_EXTRAIDO,
#  UFS_SUL,
#  ANO_SAEB,
#  DIR_INTERIM,
#  DB_PATH,
#  force = TRUE
#)

cli::cli_h2("[STAGE 5]: Creating the database")
# =============================================================================
# 5. CREATING THE DATABASE
# =============================================================================

con <- DBI::dbConnect(duckdb::duckdb(), DB_PATH)

save_table(con, ESCOLAS, "escolas", "CO_ENTIDADE")
#gravar_tabela(con, docentes_agg,   "docentes_agg",  "CO_ENTIDADE")
#gravar_tabela(con, ideb_completo,  "ideb",          "co_entidade")


cli::cli_h1("\n✅ [PIPELINE] completed successfully! Database saved in {.file {DB_PATH}}")
