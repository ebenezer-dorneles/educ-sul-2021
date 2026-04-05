# =============================================================================
# PIPELINE DE INGESTÃO DE DADOS — IDEB / CENSO ESCOLAR / IBGE
# Projeto: Fatores de desempenho no IDEB — interior da Região Sul
# Autor  : ---
# Criado : 2025
# R      : >= 4.2
# =============================================================================
# Pacotes necessários:
#  install.packages(c("duckdb", "DBI", "data.table", "readxl",
#                      "dplyr", "stringr", "fs", "httr2", "cli", "here", "purrr"))
# =============================================================================

library(duckdb)
library(DBI)
library(data.table)
library(readxl)
library(dplyr)
library(stringr)
library(fs)
library(httr2)
library(cli)
library(here)
library(purrr)

# =============================================================================
# 0. CONFIGURAÇÃO GERAL
# =============================================================================

# UFs do Sul: Paraná (41), Santa Catarina (42), Rio Grande do Sul (43)
UFS_SUL <- c("41", "42", "43")

# Ano de referência principal
ANO_CENSO  <- 2023
ANO_IDEB   <- 2023  # disponível; use 2021 se quiser evitar efeitos pós-pandemia

# Diretórios do projeto
DIR_ROOT    <- here::here()   # raiz do projeto R (use setwd() se não usar {here})
DIR_RAW     <- fs::path(DIR_ROOT, "data", "raw")
DIR_INTERIM <- fs::path(DIR_ROOT, "data", "interim")
DIR_DB      <- fs::path(DIR_ROOT, "data", "db")

# Cria estrutura de pastas se não existir
fs::dir_create(c(DIR_RAW, DIR_INTERIM, DIR_DB))
fs::dir_create(fs::path(DIR_RAW, c("censo_escolar", "ideb", "ibge")))

# Caminho do banco DuckDB
DB_PATH <- fs::path(DIR_DB, "ideb_sul.duckdb")

# =============================================================================
# 1. FUNÇÕES UTILITÁRIAS
# =============================================================================

#' Download com progresso e verificação de arquivo já existente
#' @param url  URL do arquivo
#' @param dest Caminho de destino local
#' @param force Força re-download mesmo se arquivo existir
baixar_arquivo <- function(url, dest, force = FALSE) {
  if (fs::file_exists(dest) && !force) {
    cli::cli_alert_success("Já existe: {.file {fs::path_file(dest)}} — pulando download.")
    return(invisible(dest))
  }
  cli::cli_progress_step("Baixando {.url {url}}")
  tryCatch({
    req <- httr2::request(url) |>
      httr2::req_timeout(600) |>       # 10 min — arquivos grandes
      httr2::req_retry(max_tries = 3)
    resp <- httr2::req_perform(req, path = dest)
    cli::cli_alert_success("Salvo em {.file {dest}}")
  }, error = function(e) {
    cli::cli_alert_danger("Falha no download: {e$message}")
    stop(e)
  })
  invisible(dest)
}

#' Descompacta ZIP preservando apenas os arquivos que interessam
#' @param zip_path  Caminho do arquivo ZIP
#' @param dest_dir  Diretório de destino
#' @param pattern   Regex para filtrar arquivos dentro do ZIP
descompactar <- function(zip_path, dest_dir, pattern = "\\.csv$|\\.xlsx?$") {
  cli::cli_progress_step("Descompactando {.file {fs::path_file(zip_path)}}")
  todos   <- unzip(zip_path, list = TRUE)$Name
  filtro  <- todos[str_detect(todos, regex(pattern, ignore_case = TRUE))]
  if (length(filtro) == 0) {
    cli::cli_alert_warning("Nenhum arquivo CSV/XLSX encontrado no ZIP.")
    return(invisible(NULL))
  }
  unzip(zip_path, files = filtro, exdir = dest_dir, junkpaths = TRUE)
  cli::cli_alert_success("{length(filtro)} arquivo(s) extraído(s) em {.file {dest_dir}}")
  invisible(fs::path(dest_dir, fs::path_file(filtro)))
}

# =============================================================================
# 2. DOWNLOAD DOS ARQUIVOS BRUTOS
# =============================================================================

cli::cli_h1("ETAPA 1 — Download dos arquivos brutos")

# --- 2.1 Censo Escolar -------------------------------------------------------
# O ZIP do Censo contém CSVs separados por entidade: escolas, docentes, turmas,
# matrículas e gestores. Para este projeto, usamos escolas + docentes.
url_censo <- glue::glue(
  "https://download.inep.gov.br/dados_abertos/microdados_censo_escolar_{ANO_CENSO}.zip"
)
zip_censo  <- fs::path(DIR_RAW, "censo_escolar", glue::glue("censo_{ANO_CENSO}.zip"))
baixar_arquivo(url_censo, zip_censo)

# --- 2.2 IDEB — resultados por escola ----------------------------------------
# O INEP disponibiliza planilhas Excel separadas por etapa.
# Anos iniciais (EF1), anos finais (EF2) e ensino médio (EM).
ideb_urls <- list(
  ef1 = glue::glue("https://download.inep.gov.br/ideb/planilhas_para_download/divulgacao_anos_iniciais_escolas_{ANO_IDEB}.xlsx"),
  ef2 = glue::glue("https://download.inep.gov.br/ideb/planilhas_para_download/divulgacao_anos_finais_escolas_{ANO_IDEB}.xlsx")
)
purrr::iwalk(ideb_urls, function(url, nome) {
  dest <- fs::path(DIR_RAW, "ideb", glue::glue("ideb_{nome}_{ANO_IDEB}.xlsx"))
  baixar_arquivo(url, dest)
})

# --- 2.3 IBGE — PIB municipal e outros indicadores ---------------------------
# PIB municipal (série histórica) — CSV do SIDRA / dados.gov.br
url_pib <- "https://servicodados.ibge.gov.br/api/v3/agregados/5938/periodos/2021/variaveis/37?localidades=N6[all]"
# NOTA: Para IDH e Gini, baixe o Atlas Brasil (atlasbrasil.org.br) manualmente
#       e salve em data/raw/ibge/atlas_brasil_2013.xlsx
#       O Censo 2022 ainda está sendo publicado por variável — verificar SIDRA.

# Alternativa recomendada: usar o pacote {basedosdados} (BigQuery) ou {sidrar}
# install.packages("sidrar")
# pib_raw <- sidrar::get_sidra(api = "/t/5938/n6/all/v/37/p/2021")

cli::cli_alert_info(
  "Para IDH, Gini e % pobreza: baixe o Atlas do Desenvolvimento Humano em
  <http://www.atlasbrasil.org.br/> e salve em {.file data/raw/ibge/atlas_brasil.xlsx}"
)

# =============================================================================
# 3. EXTRAÇÃO E LIMPEZA — CENSO ESCOLAR
# =============================================================================

cli::cli_h1("ETAPA 2 — Extração e limpeza do Censo Escolar")

dir_censo_extraido <- fs::path(DIR_RAW, "censo_escolar", as.character(ANO_CENSO))
fs::dir_create(dir_censo_extraido)

# Descompacta apenas os CSVs de escolas e docentes (os maiores do pacote)
descompactar(zip_censo, dir_censo_extraido, pattern = "escola|docente|profissional")

# --- 3.1 Escolas -------------------------------------------------------------
arquivo_escola <- fs::dir_ls(dir_censo_extraido, regexp = regex("escola", ignore_case = TRUE))

cli::cli_progress_step("Lendo microdados de escolas...")

# data.table::fread é o mais rápido para CSVs grandes (>1GB)
# O Censo usa encoding Latin1 (ISO-8859-1) e separador ";"
escolas_raw <- data.table::fread(
  arquivo_escola[1],
  sep           = ";",
  encoding      = "Latin-1",
  na.strings    = c("", "NA", "88888888", "99999999"),  # códigos de missing do INEP
  showProgress  = TRUE,
  colClasses    = "character"   # lê tudo como char primeiro para evitar perda de zeros à esquerda
)

cli::cli_alert_success("Escolas lidas: {nrow(escolas_raw):,} linhas, {ncol(escolas_raw)} colunas")

# Seleciona apenas colunas relevantes e filtra para a Região Sul
# Referência de colunas: Dicionário de Dados do Censo (arquivo 'leia-me' no ZIP)
colunas_escola <- c(
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
  # Infraestrutura
  "IN_AGUA_POTAVEL",
  "IN_ENERGIA_REDE_PUBLICA",
  "IN_ESGOTO_REDE_PUBLICA",
  "IN_INTERNET",
  "IN_INTERNET_ALUNOS",
  "IN_BANDA_LARGA",
  "IN_LABORATORIO_INFORMATICA",
  "IN_LABORATORIO_CIENCIAS",
  "IN_BIBLIOTECA",
  "IN_SALA_LEITURA",
  "IN_QUADRA_ESPORTES",
  "IN_QUADRA_ESPORTES_COBERTA",
  "IN_SALA_ATENDIMENTO_ESPECIAL",
  "QT_SALAS_UTILIZADAS",
  "QT_SALAS_UTILIZADAS_DENTRO",
  # Computadores
  "QT_COMP_ALUNO",
  "QT_DESKTOP_ALUNO",
  "QT_NOTEBOOK_ALUNO",
  "QT_TABLET_ALUNO"
)

# Mantém só colunas que existem (proteção contra variações entre anos)
colunas_escola <- intersect(colunas_escola, names(escolas_raw))

escolas <- escolas_raw[
  CO_UF %in% UFS_SUL & TP_SITUACAO_FUNCIONAMENTO == "1",
  ..colunas_escola
]

# Conversão de tipos
cols_int  <- c("QT_SALAS_UTILIZADAS", "QT_SALAS_UTILIZADAS_DENTRO",
               "QT_COMP_ALUNO", "QT_DESKTOP_ALUNO", "QT_NOTEBOOK_ALUNO", "QT_TABLET_ALUNO")
cols_bool <- colunas_escola[str_starts(colunas_escola, "IN_")]

escolas[, (cols_int)  := lapply(.SD, as.integer), .SDcols = intersect(cols_int, names(escolas))]
escolas[, (cols_bool) := lapply(.SD, function(x) as.integer(x) == 1L),
        .SDcols = intersect(cols_bool, names(escolas))]
escolas[, CO_MUNICIPIO := str_pad(CO_MUNICIPIO, 7, pad = "0")]

# Adiciona ano de referência
escolas[, ano_censo := ANO_CENSO]

cli::cli_alert_success("Escolas Sul filtradas: {nrow(escolas):,} registros")

# --- 3.2 Docentes — agregação por escola ------------------------------------
arquivo_docente <- fs::dir_ls(
  dir_censo_extraido,
  regexp = regex("docente|profissional", ignore_case = TRUE)
)

cli::cli_progress_step("Lendo e agregando microdados de docentes...")

# Docentes é o maior arquivo (~3-4GB). Lemos apenas as colunas necessárias.
colunas_docente <- c(
  "CO_ENTIDADE",
  "NU_ANO_CENSO",
  "TP_ESCOLARIDADE",   # 1=sem fund., ..., 5=superior completo, 6=especializacao, 7=mestrado, 8=doutorado
  "TP_TIPO_DOCENTE",   # 1=docente, 2=auxiliar/assistente
  "TP_SITUACAO_DOCENTE" # 1=ativo
)
colunas_docente <- intersect(colunas_docente, names(
  data.table::fread(arquivo_docente[1], nrows = 0, sep = ";", encoding = "Latin-1")
))

docentes_raw <- data.table::fread(
  arquivo_docente[1],
  sep          = ";",
  encoding     = "Latin-1",
  na.strings   = c("", "NA"),
  showProgress = TRUE,
  select       = colunas_docente
)

# Mantém apenas docentes ativos das escolas da Região Sul
escolas_ids <- escolas$CO_ENTIDADE
docentes_sul <- docentes_raw[
  CO_ENTIDADE %in% escolas_ids & TP_SITUACAO_DOCENTE == "1" & TP_TIPO_DOCENTE == "1"
]

# Agrega por escola: % com superior, % com pós-graduação
docentes_agg <- docentes_sul[, .(
  qt_docentes       = .N,
  pct_superior      = round(mean(as.integer(TP_ESCOLARIDADE) >= 5, na.rm = TRUE) * 100, 1),
  pct_pos_graduacao = round(mean(as.integer(TP_ESCOLARIDADE) >= 6, na.rm = TRUE) * 100, 1)
), by = .(CO_ENTIDADE)]

docentes_agg[, ano_censo := ANO_CENSO]

cli::cli_alert_success("Docentes agregados: {nrow(docentes_agg):,} escolas com dados")

# Libera memória
rm(escolas_raw, docentes_raw, docentes_sul)
gc()

# =============================================================================
# 4. EXTRAÇÃO E LIMPEZA — IDEB
# =============================================================================

cli::cli_h1("ETAPA 3 — Limpeza dos dados do IDEB")

#' Lê e padroniza uma planilha IDEB por escola
#' O Excel do INEP tem cabeçalho nas primeiras linhas — pule-as com skip
ler_ideb <- function(caminho, etapa) {
  cli::cli_progress_step("Lendo IDEB {etapa}...")

  # Detecta quantas linhas pular lendo as primeiras
  raw <- readxl::read_excel(caminho, sheet = 1, n_max = 10, col_names = FALSE)

  # Linha do cabeçalho real: procura por "CO_ENTIDADE" ou "Código"
  linha_header <- which(apply(raw, 1, function(r) any(str_detect(r, "CO_ENTIDADE|Código|codigo"), na.rm = TRUE)))
  skip_n <- if (length(linha_header) > 0) linha_header[1] - 1L else 8L

  df <- readxl::read_excel(
    caminho,
    sheet     = 1,
    skip      = skip_n,
    col_types = "text"
  )

  # Padroniza nomes de colunas
  names(df) <- names(df) |>
    str_to_upper() |>
    str_replace_all("[^A-Z0-9_]", "_") |>
    str_replace_all("__+", "_") |>
    str_remove("_$")

  # Identifica colunas de IDEB (padrão: VL_OBSERVADO_XXXX)
  col_ideb     <- names(df)[str_detect(names(df), "VL_OBSERVADO|IDEB_[0-9]")]
  col_nota     <- names(df)[str_detect(names(df), "VL_NOTA|MEDIA_[0-9]|PROFICIENCIA")]
  col_aprovacao <- names(df)[str_detect(names(df), "VL_APROVACAO|TX_APROVACAO")]

  # Reformata para formato longo (um ano por linha)
  anos_disponiveis <- str_extract(col_ideb, "[0-9]{4}") |> unique() |> sort()

  resultado <- purrr::map_dfr(anos_disponiveis, function(ano) {
    col_i <- col_ideb[str_detect(col_ideb, ano)]
    col_n <- col_nota[str_detect(col_nota, ano)]
    col_a <- col_aprovacao[str_detect(col_aprovacao, ano)]

    df |>
      transmute(
        co_entidade  = as.character(.data[["CO_ENTIDADE"]] %||% .data[[names(df)[1]]]),
        ano          = as.integer(ano),
        etapa        = etapa,
        vl_ideb      = as.numeric(if (length(col_i) > 0) .data[[col_i[1]]] else NA),
        vl_nota_saeb = as.numeric(if (length(col_n) > 0) .data[[col_n[1]]] else NA),
        vl_aprovacao = as.numeric(if (length(col_a) > 0) .data[[col_a[1]]] else NA)
      ) |>
      filter(!is.na(co_entidade), !is.na(vl_ideb))
  })

  cli::cli_alert_success("{nrow(resultado):,} registros IDEB ({etapa})")
  resultado
}

# Lê as duas etapas
arquivo_ef1 <- fs::path(DIR_RAW, "ideb", glue::glue("ideb_ef1_{ANO_IDEB}.xlsx"))
arquivo_ef2 <- fs::path(DIR_RAW, "ideb", glue::glue("ideb_ef2_{ANO_IDEB}.xlsx"))

ideb_ef1 <- ler_ideb(arquivo_ef1, "anos_iniciais")
ideb_ef2 <- ler_ideb(arquivo_ef2, "anos_finais")

ideb_completo <- bind_rows(ideb_ef1, ideb_ef2) |>
  filter(co_entidade %in% escolas$CO_ENTIDADE)   # mantém só escolas do Sul

cli::cli_alert_success("IDEB total Sul: {nrow(ideb_completo):,} registros")

# =============================================================================
# 5. EXTRAÇÃO E LIMPEZA — DADOS MUNICIPAIS (IBGE / ATLAS)
# =============================================================================

cli::cli_h1("ETAPA 4 — Dados municipais (IBGE / Atlas Brasil)")

# --- 5.1 PIB municipal via {sidrar} ------------------------------------------
# Requer: install.packages("sidrar")
# Tabela 5938 = PIB dos Municípios | Variável 37 = PIB a preços correntes (R$ mil)
pib_municipio <- tryCatch({
  sidrar::get_sidra(
    api = "/t/5938/n6/all/v/37/p/2021",
    format = 3
  ) |>
    as.data.table() |>
    transmute(
      cod_ibge    = str_pad(as.character(`Município (Código)`), 7, pad = "0"),
      pib_mil_reais = as.numeric(Valor),
      ano_ref     = 2021L
    ) |>
    filter(str_sub(cod_ibge, 1, 2) %in% UFS_SUL)
}, error = function(e) {
  cli::cli_alert_warning("sidrar não disponível ou erro na API. Use o arquivo manual.")
  NULL
})

# --- 5.2 Atlas do Desenvolvimento Humano (IDH, Gini, % pobreza) --------------
arquivo_atlas <- fs::path(DIR_RAW, "ibge", "atlas_brasil.xlsx")

if (fs::file_exists(arquivo_atlas)) {
  atlas <- readxl::read_excel(arquivo_atlas, sheet = 1) |>
    as.data.table() |>
    transmute(
      cod_ibge       = str_pad(as.character(Codmun7), 7, pad = "0"),
      nome_municipio = Município,
      uf             = UF,
      idhm_2010      = as.numeric(IDHM),
      idhm_educacao  = as.numeric(IDHM_E),
      idhm_renda     = as.numeric(IDHM_R),
      gini           = as.numeric(GINI),
      pct_pobreza    = as.numeric(PPOB),        # % pop. em extrema pobreza
      pct_vulneravel = as.numeric(PVUL),        # % pop. vulnerável
      renda_per_capita = as.numeric(RDPC),
      ano_ref        = 2010L
    ) |>
    filter(str_sub(cod_ibge, 1, 2) %in% UFS_SUL)

  cli::cli_alert_success("Atlas: {nrow(atlas):,} municípios carregados")
} else {
  cli::cli_alert_warning(
    "Arquivo {.file {arquivo_atlas}} não encontrado.
    Baixe em <http://www.atlasbrasil.org.br/acervo/atlas> e salve no caminho indicado."
  )
  atlas <- NULL
}

# Tabela municipio consolidada
if (!is.null(pib_municipio) && !is.null(atlas)) {
  municipio <- atlas |>
    left_join(
      pib_municipio |> select(cod_ibge, pib_mil_reais),
      by = "cod_ibge"
    ) |>
    mutate(
      pib_per_capita = pib_mil_reais * 1000 / NA_real_  # necessita população — veja nota abaixo
    )
  # NOTA: Para PIB per capita, junte com população do Censo 2022 (tabela SIDRA 9514)
}

# =============================================================================
# 6. PERSISTÊNCIA NO DUCKDB
# =============================================================================

cli::cli_h1("ETAPA 5 — Gravando no banco DuckDB")

con <- DBI::dbConnect(duckdb::duckdb(), DB_PATH)

gravar_tabela <- function(con, df, nome_tabela, chave = NULL) {
  cli::cli_progress_step("Gravando tabela {.val {nome_tabela}}...")

  # Sobrescreve a tabela se já existir (idempotente — seguro para re-executar)
  if (DBI::dbExistsTable(con, nome_tabela)) {
    DBI::dbRemoveTable(con, nome_tabela)
  }

  DBI::dbWriteTable(con, nome_tabela, as.data.frame(df), row.names = FALSE)

  n <- DBI::dbGetQuery(con, glue::glue("SELECT COUNT(*) AS n FROM {nome_tabela}"))$n
  cli::cli_alert_success("{nome_tabela}: {n:,} linhas gravadas")

  # Cria índice na chave primária se fornecida
  if (!is.null(chave)) {
    DBI::dbExecute(con, glue::glue(
      "CREATE INDEX IF NOT EXISTS idx_{nome_tabela}_{chave}
       ON {nome_tabela} ({chave})"
    ))
  }
}

# Grava tabelas
gravar_tabela(con, escolas,        "escola",        "CO_ENTIDADE")
gravar_tabela(con, docentes_agg,   "docentes_agg",  "CO_ENTIDADE")
gravar_tabela(con, ideb_completo,  "ideb",          "co_entidade")

if (exists("atlas") && !is.null(atlas)) {
  gravar_tabela(con, atlas,        "municipio",     "cod_ibge")
}
if (exists("pib_municipio") && !is.null(pib_municipio)) {
  gravar_tabela(con, pib_municipio, "pib_municipio", "cod_ibge")
}

# =============================================================================
# 7. VIEW ANALÍTICA — BASE PRONTA PARA MODELAGEM
# =============================================================================

cli::cli_h1("ETAPA 6 — Criando view analítica")

# Esta view junta escola + docentes + IDEB + município em uma única tabela
# pronta para passar direto para lm(), lme4::lmer() ou glm()
DBI::dbExecute(con, "
  CREATE OR REPLACE VIEW base_modelagem AS
  SELECT
    -- Identificação
    e.CO_ENTIDADE                         AS co_entidade,
    e.CO_MUNICIPIO                        AS cod_municipio,
    e.NO_ENTIDADE                         AS nome_escola,
    e.SG_UF                               AS uf,
    e.TP_DEPENDENCIA                      AS tp_dependencia,
    e.TP_LOCALIZACAO                      AS tp_localizacao,

    -- Infraestrutura escolar
    e.IN_INTERNET                         AS in_internet,
    e.IN_BANDA_LARGA                      AS in_banda_larga,
    e.IN_LABORATORIO_INFORMATICA          AS in_lab_info,
    e.IN_BIBLIOTECA OR e.IN_SALA_LEITURA  AS in_biblioteca,
    e.IN_QUADRA_ESPORTES_COBERTA          AS in_quadra,
    e.QT_SALAS_UTILIZADAS                 AS qt_salas,
    COALESCE(e.QT_COMP_ALUNO, 0)
      + COALESCE(e.QT_DESKTOP_ALUNO, 0)
      + COALESCE(e.QT_NOTEBOOK_ALUNO, 0) AS qt_computadores,

    -- Docentes
    d.qt_docentes,
    d.pct_superior,
    d.pct_pos_graduacao,

    -- IDEB (anos iniciais e finais separados)
    i_ei.vl_ideb                          AS ideb_anos_iniciais,
    i_ei.vl_nota_saeb                     AS nota_saeb_ei,
    i_ei.vl_aprovacao                     AS aprovacao_ei,
    i_ef.vl_ideb                          AS ideb_anos_finais,
    i_ef.vl_nota_saeb                     AS nota_saeb_ef,
    i_ef.vl_aprovacao                     AS aprovacao_ef,

    -- Município (socioeconômico)
    m.nome_municipio,
    m.idhm_2010,
    m.idhm_educacao,
    m.gini,
    m.pct_pobreza,
    m.renda_per_capita,
    p.pib_mil_reais

  FROM escola e
  LEFT JOIN docentes_agg     d   ON e.CO_ENTIDADE  = d.CO_ENTIDADE
  LEFT JOIN ideb             i_ei ON e.CO_ENTIDADE = i_ei.co_entidade
                                 AND i_ei.etapa    = 'anos_iniciais'
                                 AND i_ei.ano      = 2023
  LEFT JOIN ideb             i_ef ON e.CO_ENTIDADE = i_ef.co_entidade
                                 AND i_ef.etapa    = 'anos_finais'
                                 AND i_ef.ano      = 2023
  LEFT JOIN municipio        m   ON e.CO_MUNICIPIO = m.cod_ibge
  LEFT JOIN pib_municipio    p   ON e.CO_MUNICIPIO = p.cod_ibge
")

cli::cli_alert_success("View {.val base_modelagem} criada com sucesso")

# =============================================================================
# 8. VERIFICAÇÃO FINAL
# =============================================================================

cli::cli_h1("ETAPA 7 — Verificação final do banco")

tabelas <- DBI::dbListTables(con)
cli::cli_alert_info("Tabelas no banco: {paste(tabelas, collapse=', ')}")

# Contagens
purrr::walk(tabelas, function(t) {
  n <- DBI::dbGetQuery(con, glue::glue("SELECT COUNT(*) AS n FROM {t}"))$n
  cli::cli_bullets(c("*" = "{t}: {n:,} linhas"))
})

# Preview da base de modelagem
preview <- DBI::dbGetQuery(con, "
  SELECT COUNT(*)                                    AS total_escolas,
         COUNT(ideb_anos_iniciais)                   AS com_ideb_ei,
         COUNT(ideb_anos_finais)                     AS com_ideb_ef,
         ROUND(AVG(ideb_anos_iniciais), 3)           AS media_ideb_ei,
         ROUND(AVG(ideb_anos_finais), 3)             AS media_ideb_ef,
         ROUND(AVG(pct_superior), 1)                 AS media_pct_superior,
         ROUND(AVG(idhm_2010), 3)                    AS media_idhm
  FROM base_modelagem
")
print(preview)

DBI::dbDisconnect(con, shutdown = TRUE)
cli::cli_alert_success("Pipeline concluída! Banco salvo em {.file {DB_PATH}}")

# =============================================================================
# 9. COMO USAR O BANCO NAS ANÁLISES
# =============================================================================
#
# library(duckdb); library(DBI); library(dplyr)
#
# con <- dbConnect(duckdb(), "data/db/ideb_sul.duckdb", read_only = TRUE)
#
# # Carrega base pronta para modelagem
# base <- tbl(con, "base_modelagem") |> collect()
#
# # Regressão linear simples
# m1 <- lm(ideb_anos_iniciais ~ pct_superior + in_internet + idhm_2010 + gini,
#           data = base, na.action = na.omit)
# summary(m1)
#
# # Modelo multinível (escolas aninhadas em municípios)
# library(lme4)
# m2 <- lmer(ideb_anos_iniciais ~ pct_superior + in_internet + idhm_2010
#              + (1 | cod_municipio),
#            data = base, na.action = na.omit)
# summary(m2)
#
# dbDisconnect(con, shutdown = TRUE)
# =============================================================================
