
#' @title Clean the microdata census escolar 2023
#' @description Clean the microdata census escolar 2023
#' @param DIR_CENSO_EXTRAIDO Directory where the microdata census escolar 2023 is extracted
#' @param UFS_SUL Vector of UFs to be included in the analysis
#' @param ANO_CENSO Year of the microdata census escolar
#' @param force Logical, whether to force re-cleaning
clean_escolas <- function(
    DIR_CENSO_EXTRAIDO,
    UFS_SUL,
    ANO_CENSO,
    force = FALSE
    ) {

ESCOLAS <- fs::path(DIR_CENSO_EXTRAIDO, "microdados_censo_escolar_2023/dados/microdados_ed_basica_2023.csv")

ESCOLAS_RAW <- data.table::fread(
  ESCOLAS[1],
  sep           = ";",
  encoding      = "Latin-1",
  na.strings    = c("", "NA", "88888888", "99999999"),  # códigos de missing do INEP
  showProgress  = TRUE,
  colClasses    = "character"   # lê tudo como char primeiro para evitar perda de zeros à esquerda
)

COLUNAS_ESCOLA <- c(
  # Identificação
  "CO_ENTIDADE",       # código único da escola (chave primária)
  "CO_MUNICIPIO",      # código IBGE 7 dígitos do município
  "NO_ENTIDADE",       # nome da escola
  "SG_UF",             # UF (41=PR, 42=SC, 43=RS)
  "CO_UF",
  # Dependência e localização
  "TP_DEPENDENCIA",    # 1=federal, 2=estadual, 3=municipal, 4=privada
  "TP_LOCALIZACAO",    # 1=urbana, 2=rural
  "TP_SITUACAO_FUNCIONAMENTO",  # 1=em atividade
  # Matriculas
  "QT_MAT_FUND_AF",
  "QT_MAT_MED",
  # Docentes
  "QT_DOC_FUND",
  "QT_DOC_MED",
  # Turmas
  "QT_TUR_FUND",
  "QT_TUR_MED",
  # Infraestrutura
  "IN_AGUA_POTAVEL",
  "IN_ENERGIA_REDE_PUBLICA",
  "IN_ESGOTO_REDE_PUBLICA",
  #
  "IN_INTERNET",
  "IN_INTERNET_ALUNOS",
  "IN_INTERNET_APRENDIZAGEM",
  "IN_BANDA_LARGA",
  "IN_LABORATORIO_INFORMATICA",
  "IN_REDES_SOCIAIS",
  #
  "IN_LABORATORIO_CIENCIAS",
  "IN_BIBLIOTECA",
  "IN_SALA_LEITURA",
  "IN_QUADRA_ESPORTES",
  "IN_QUADRA_ESPORTES_COBERTA",
  #
  "IN_SALA_ATENDIMENTO_ESPECIAL",
  "QT_SALAS_UTILIZADAS",
  "QT_SALAS_UTILIZADAS_DENTRO",
  "QT_SALAS_UTILIZA_CLIMATIZADAS",
  "QT_SALAS_UTILIZADAS_ACESSIVEIS",
  # Computadores
  "QT_DESKTOP_ALUNO",
  "QT_COMP_PORTATIL_ALUNO",
  "QT_TABLET_ALUNO"
)

# Mantém só colunas que existem (proteção contra variações entre anos)
COLUNAS_ESCOLA <- intersect(COLUNAS_ESCOLA, names(ESCOLAS_RAW))

ESCOLAS <- ESCOLAS_RAW[
  CO_UF %in% UFS_SUL & TP_SITUACAO_FUNCIONAMENTO == "1",
  ..COLUNAS_ESCOLA
]

COLS_INT <- COLUNAS_ESCOLA[stringr::str_starts(COLUNAS_ESCOLA, "QT_")]
COLS_INT_EXIST <- intersect(COLS_INT, names(ESCOLAS))

COLS_BOOL <- COLUNAS_ESCOLA[stringr::str_starts(COLUNAS_ESCOLA, "IN_")]
COLS_BOOL_EXIST <- intersect(COLS_BOOL, names(ESCOLAS))

ESCOLAS[, (COLS_INT_EXIST)  := lapply(.SD, as.integer), .SDcols = COLS_INT_EXIST]
ESCOLAS[, (COLS_BOOL_EXIST) := lapply(.SD, function(x) as.integer(x) == 1L),
        .SDcols = COLS_BOOL_EXIST]
ESCOLAS[, CO_MUNICIPIO := stringr::str_pad(CO_MUNICIPIO, 7, pad = "0")]
ESCOLAS[, ano_censo := ANO_CENSO]

return(ESCOLAS)
}


