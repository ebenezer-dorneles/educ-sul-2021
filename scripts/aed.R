pkgs <- c("DBI", "duckdb", "dplyr", "dbplyr", "tidyr", "ggplot2",
          "psych", "lme4", "lmerTest", "performance",
          "scales", "broom.mixed", "forcats")

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
  group_by(ID_LOCALIZACAO, ID_UF) %>% 
  summarise(total = n(), .groups = "drop") %>% 
  # Agrupa apenas por UF para que o sum(total) seja o total do Estado
  group_by(ID_UF) %>% 
  mutate(percentual_uf = scales::percent(total / sum(total))) %>% 
  ungroup() %>% # Boa prática: desagrupar ao final das operações
  mutate(percentual_estado = scales::percent(total / sum(total))) %>% 
  mutate(ID_LOCALIZACAO = case_when(
    ID_LOCALIZACAO == 1 ~ 'Urbana',
    ID_LOCALIZACAO == 2 ~ 'Rural',
    .default  = 'Nope'
  )) %>% 
  mutate(ID_UF = case_when(
    ID_UF == 41L ~ 'Parana',
    ID_UF == 42L ~ 'Santa Catarina',
    ID_UF == 43L ~ 'Rio Grande do Sul',
    .default = 'Nope'
  ))


# PERGUNTA : Quantos alunos do ensino médio por tipo de ensino?
alunos_raw %>% 
  group_by(ID_SERIE, ID_UF) %>% 
  summarise(total = n(), .groups = "drop") %>% 
  group_by(ID_UF) %>% 
  mutate(percentual_uf = scales::percent(total / sum(total))) %>% 
  ungroup() %>% # Boa prática: desagrupar ao final das operações
  mutate(percentual_estado = scales::percent(total / sum(total))) %>% 
  mutate(ID_UF = case_when(
    ID_UF == 41L ~ 'Parana',
    ID_UF == 42L ~ 'Santa Catarina',
    ID_UF == 43L ~ 'Rio Grande do Sul',
    .default = 'Nope'
  )) %>% 
  mutate(ID_SERIE = case_when(
    ID_SERIE == 12 ~ "3ª/4ª séries do Ensino Médio Tradicional",
    ID_SERIE == 13 ~ "3ª/4ª séries do Ensino Médio Integrado",
    .default = "Nope"
  ))

#PERGUNTA: Qual a porcentagem de escolas publicas no saeb 2023?
  alunos_raw %>% 
  group_by(IN_PUBLICA, ID_UF) %>% 
  summarise(total = n(), .groups = "drop") %>% 
  # Agrupa apenas por UF para que o sum(total) seja o total do Estado
  group_by(ID_UF) %>% 
  mutate(percentual_uf = scales::percent(total / sum(total))) %>% 
  ungroup() %>% # Boa prática: desagrupar ao final das operações
  mutate(percentual_estado = scales::percent(total / sum(total))) %>% 
  mutate(IN_PUBLICA = case_when(
    IN_PUBLICA == 1 ~ 'Publica',
    IN_PUBLICA == 0 ~ 'Privada',
    .default  = 'Nope'
  )) %>% 
  mutate(ID_UF = case_when(
    ID_UF == 41L ~ 'Parana',
    ID_UF == 42L ~ 'Santa Catarina',
    ID_UF == 43L ~ 'Rio Grande do Sul',
    .default = 'Nope'
  ))

  # Pegunta qual o nivel socioeconomico dos estudantes?
alunos_raw %>% 
  group_by(NU_TIPO_NIVEL_INSE) %>% 
  summarise(total = n(), .groups = "drop") %>% 
  mutate(
    # 1. Mantém a proporção numérico-contínua (ex: 0.15)
    percentual = total / sum(total),
    
    # 2. Converte para Factor mantendo a ordem correta dos níveis socioeconômicos
    NU_TIPO_NIVEL_INSE_STR = factor(
      NU_TIPO_NIVEL_INSE,
      levels = 1:7,
      labels = c('Muito Baixo', 'Baixo', 'Médio Baixo', 'Médio', 'Médio Alto', 'Alto', 'Muito Alto')
    )
  ) %>% 
  # Opcional: remove registros com códigos fora do intervalo 1-7 (como os que davam 'Nope')
  drop_na(NU_TIPO_NIVEL_INSE_STR) %>% 
  ggplot(aes(x = NU_TIPO_NIVEL_INSE_STR, y = percentual, fill = NU_TIPO_NIVEL_INSE_STR)) + 
    geom_col() + 
    # Formata a escala do eixo Y para porcentagem corretamente
    scale_y_continuous(labels = scales::percent_format(accuracy = 1)) + 
    labs(
      subtitle = "Nível Socioeconômico dos Estudantes",
      x = "Nível Socioeconômico",
      y = "Percentual"
    ) + 
    scale_fill_brewer(palette = "Set3") + 
    theme_minimal() + 
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      legend.position = "none" # Opcional: remove a legenda lateral, já que o eixo X já identifica as cores
    )
   
  