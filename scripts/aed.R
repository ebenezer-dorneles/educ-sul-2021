pkgs <- c("DBI", "duckdb", "dplyr", "tidyr", "ggplot2",
          "psych", "lme4", "lmerTest", "performance",
          "scales", "broom.mixed")

invisible(lapply(pkgs, function(p) {
  if (!require(p, character.only = TRUE, quietly = TRUE))
    install.packages(p, quiet = TRUE)
  library(p, character.only = TRUE)
}))

con <- DBI::dbConnect(
  duckdb::duckdb(),
  "data/db/saeb_sul_2023.duckdb",
  read_only = TRUE
)

# -----------------------------------------------------------------------------
# 1. CARREGAMENTO E FILTROS
# -----------------------------------------------------------------------------

alunos_raw <- tbl(con, "alunos") |>
  filter(
    ID_REGIAO == 4,
    ID_UF %in% c(41L, 42L, 43L),
    IN_PRESENCA_LP == 1,
    IN_PRESENCA_MT == 1,
    IN_PROFICIENCIA_LP == 1,
    IN_PREENCHIMENTO_QUESTIONARIO == 1
  ) |>
  collect()

DBI::dbDisconnect(con, shutdown = TRUE)


dplyr::glimpse(alunos_raw)

# CONTEXTO : Dados de alunos do ensino médio que realizaram  e reponseram o 
# questionáriosa prova do saeb em escolas do sul do Brasil no ano de 2023.

# PERGUNTA : Quantos alunos de escolas urbana|rurais?
alunos_raw %>% 
  group_by(ID_LOCALIZACAO) %>% 
  summarise(total = n()) %>% 
  mutate(ID_LOCALIZACAO = case_when(
    ID_LOCALIZACAO == 1 ~ 'Urbana',
    ID_LOCALIZACAO == 2 ~ 'Rural',
    .default  = 'Nope'
  ))


# PERGUNTA : Quantos alunos do ensino médio por tipo de ensino?
alunos_raw %>% 
  group_by(ID_SERIE) %>% 
  summarise(total = n()) %>% 
  mutate(ID_SERIE = case_when(
    ID_SERIE == 12 ~ "3ª/4ª séries do Ensino Médio Tradicional",
    ID_SERIE == 13 ~ "3ª/4ª séries do Ensino Médio Integrado",
    .default = "Nope"
  ))
