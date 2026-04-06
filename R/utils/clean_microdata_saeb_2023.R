
#' @title Clean the microdata saeb 2023
#' @description Clean the microdata saeb 2023
#' @param DIR_CENSO_EXTRAIDO Directory where the microdata saeb 2023 is extracted
#' @param UFS_SUL Vector of UFs to be included in the analysis
#' @param ANO_CENSO Year of the microdata saeb 2023
clean_professores <- function(
    DIR_CENSO_EXTRAIDO,
    UFS_SUL,
    ANO_CENSO
    ) {

  PROFESSORES <- fs::path(DIR_CENSO_EXTRAIDO, "MICRODADOS_SAEB_2023/DADOS/TS_PROFESSOR.csv")

  PROFESSORES_RAW <- data.table::fread(
    PROFESSORES[1],
    sep           = ";",
    encoding      = "Latin-1",
    na.strings    = c("", "NA", "88888888", "99999999"),
    showProgress  = TRUE,
    colClasses    = "character"
  )

  PROFESSORES <- PROFESSORES_RAW[ID_UF %in% UFS_SUL]

  return(PROFESSORES)
}


#' @title Clean the microdata saeb 2023
#' @description Clean the microdata saeb 2023
#' @param DIR_CENSO_EXTRAIDO Directory where the microdata saeb 2023 is extracted
#' @param UFS_SUL Vector of UFs to be included in the analysis
#' @param ANO_CENSO Year of the microdata saeb 2023
clean_escolas <- function(
    DIR_CENSO_EXTRAIDO,
    UFS_SUL,
    ANO_CENSO
    ) {

  ESCOLAS <- fs::path(DIR_CENSO_EXTRAIDO, "MICRODADOS_SAEB_2023/DADOS/TS_ESCOLA.csv")

  ESCOLAS_RAW <- data.table::fread(
    ESCOLAS[1],
    sep           = ";",
    encoding      = "Latin-1",
    na.strings    = c("", "NA", "88888888", "99999999"),
    showProgress  = TRUE,
    colClasses    = "character"
  )

  ESCOLAS <- ESCOLAS_RAW[ID_UF %in% UFS_SUL]

  return(ESCOLAS)
}

#' @title Clean the microdata saeb 2023
#' @description Clean the microdata saeb 2023
#' @param DIR_CENSO_EXTRAIDO Directory where the microdata saeb 2023 is extracted
#' @param UFS_SUL Vector of UFs to be included in the analysis
#' @param ANO_CENSO Year of the microdata saeb 2023
clean_alunos <- function(
    DIR_CENSO_EXTRAIDO,
    UFS_SUL,
    ANO_CENSO
    ) {

  ALUNOS <- fs::path(DIR_CENSO_EXTRAIDO, "MICRODADOS_SAEB_2023/DADOS/TS_ALUNO_34EM.csv")

  ALUNOS_RAW <- data.table::fread(
    ALUNOS[1],
    sep           = ";",
    encoding      = "Latin-1",
    na.strings    = c("", "NA", "88888888", "99999999"),
    showProgress  = TRUE,
    colClasses    = "character"
  )

  ALUNOS <- ALUNOS_RAW[ID_UF %in% UFS_SUL]

  return(ALUNOS)
}


