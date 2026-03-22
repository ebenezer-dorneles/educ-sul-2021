source("scripts/main.R")

library(dplyr)
library(tidyr)


data_censo_2025$list_tables()

# Carregar dados
df_professores_filtered <- data_censo_2025$get_table("Tabela_Docente_2025.csv")

# Filtrar dados
identificacao_escolas_sul <- readr::read_csv("data/processed/identificacao_escolas_sul.csv")

# Filtrar professores que estão em escolas do sul
df_professores_filtered <- df_professores_filtered %>%
  dplyr::filter(CO_ENTIDADE %in% identificacao_escolas_sul$CO_ENTIDADE)

glimpse(df_professores_filtered)

# Quantos professores tem em cada faixa etária no sul do Brasil?
df_professores_filtered %>%
  dplyr::select(
    QT_DOC_BAS_0_24,
    QT_DOC_BAS_25_29,
    QT_DOC_BAS_30_39,
    QT_DOC_BAS_40_49,
    QT_DOC_BAS_50_54,
    QT_DOC_BAS_55_59,
    QT_DOC_BAS_60_MAIS
  ) %>%
  pivot_longer(
    cols = everything(),
    names_to = "faixa_etaria",
    values_to = "quantidade"
  ) %>%
  group_by(faixa_etaria) %>%
  summarise(
    total = sum(quantidade, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    percentual = scales::percent(total / sum(total))
  ) %>%
  arrange(desc(total))
  
# formação dos professores no sul do Brasil
df_professores_filtered %>%
  dplyr::select(
    QT_DOC_BAS_ESCO_EF,
    QT_DOC_BAS_ESCO_EM,
    QT_DOC_BAS_ESCO_SUP_GRAD,
    QT_DOC_BAS_ESCO_SUP_GRAD_LICEN,
    QT_DOC_BAS_ESCO_SUP_GRAD_SLICEN,
    QT_DOC_BAS_ESCO_SUP_POS_ESPEC,
    QT_DOC_BAS_ESCO_SUP_POS_MESTRA,
    QT_DOC_BAS_ESCO_SUP_POS_DOUTO,
    QT_DOC_BAS_ESCO_SUP_POS_NENHUM
  ) %>%
  pivot_longer(
    cols = everything(),
    names_to = "categoria",
    values_to = "quantidade"
  ) %>%
  summarise(
    total = sum(quantidade, na.rm = TRUE),
    .by = categoria
  ) %>%
  mutate(
    percentual = scales::percent(total / sum(total))
  ) %>% 
  arrange(desc(total))

# Professores por regime de trabalho
df_professores_filtered %>% 
  dplyr::select(
    QT_DOC_BAS_VINCULO_CONCUR,
    QT_DOC_BAS_VINCULO_CONTRA,
    QT_DOC_BAS_VINCULO_TERCEIR,
    QT_DOC_BAS_VINCULO_CLT
  ) %>% 
  pivot_longer(
    cols = everything(),
    names_to = "regime_trabalho",
    values_to = "quantidade"
  ) %>% 
  group_by(regime_trabalho) %>% 
  summarise(
    total = sum(quantidade, na.rm = TRUE),
    .groups = "drop"
  ) %>% 
  mutate(
    percentual = scales::percent(total / sum(total))
  ) %>% 
  arrange(desc(total))

# Professores por função
df_professores_filtered %>% 
  dplyr::select(
    QT_DOC_BAS_DOCENTE,
    QT_DOC_BAS_AUXILIAR,
    QT_DOC_BAS_PROFI_MONITOR,
    QT_DOC_BAS_TRADUTOR_LIBRAS,
    QT_DOC_BAS_TITULAR_EAD,
    QT_DOC_BAS_TUTOR_AUX_EAD,
    QT_DOC_BAS_GUIA_INTERPRETE,
    QT_DOC_BAS_APOIO_PCD,
    QT_DOC_BAS_INSTRUTOR_EP
  ) %>% 
  pivot_longer(
    cols = everything(),
    names_to = "funcao",
    values_to = "quantidade"
  ) %>% 
  group_by(funcao) %>% 
  summarise(
    total = sum(quantidade, na.rm = TRUE),
    .groups = "drop"
  ) %>% 
  mutate(
    percentual = scales::percent(total / sum(total))
  ) %>% 
  arrange(desc(total))

# Formacão continuada
df_professores_filtered %>% 
  dplyr::select(
    QT_DOC_BAS_ESPEC_CRE,
    QT_DOC_BAS_ESPEC_PRE_ESCOLA,
    QT_DOC_BAS_ESPEC_ANOS_INICIAIS,
    QT_DOC_BAS_ESPEC_ANOS_FINAIS,
    QT_DOC_BAS_ESPEC_ENS_MEDIO,
    QT_DOC_BAS_ESPEC_EJA,
    QT_DOC_BAS_ESPEC_ED_ESPECIAL,
    QT_DOC_BAS_ESPEC_BIL_SURDOS,
    QT_DOC_BAS_ESPEC_ED_INDIGENA,
    QT_DOC_BAS_ESPEC_CAMPO,
    QT_DOC_BAS_ESPEC_AMBIENTAL,
    QT_DOC_BAS_ESPEC_DIR_HUMANOS,
    QT_DOC_BAS_ESPEC_DIV_SEXUAL,
    QT_DOC_BAS_ESPEC_DIR_ADOLESC,
    QT_DOC_BAS_ESPEC_AFRO,
    QT_DOC_BAS_ESPEC_GESTAO,
    QT_DOC_BAS_ESPEC_EDUC_TIC,
    QT_DOC_BAS_ESPEC_OUTROS,
    QT_DOC_BAS_ESPEC_NENHUM
  ) %>% 
  pivot_longer(
    cols = everything(),
    names_to = "formacao_continuada",
    values_to = "quantidade"
  ) %>% 
  group_by(formacao_continuada) %>% 
  summarise(
    total = sum(quantidade, na.rm = TRUE),
    .groups = "drop"
  ) %>% 
  mutate(
    percentual = scales::percent(total / sum(total))
  ) %>%
  arrange(desc(total))

# Disciplinas lecionadas
df_professores_filtered %>% 
  dplyr::select(
    QT_DOC_BAS_DISC_LINGUA_PORT,
    QT_DOC_BAS_DISC_EDUC_FISICA,
    QT_DOC_BAS_DISC_ARTES,
    QT_DOC_BAS_DISC_LINGUA_ING,
    QT_DOC_BAS_DISC_LINGUA_ESPA,
    QT_DOC_BAS_DISC_LINGUA_FRANC,
    QT_DOC_BAS_DISC_LINGUA_OUTRA,
    QT_DOC_BAS_DISC_LIBRAS,
    QT_DOC_BAS_DISC_LINGUA_INDIG,
    QT_DOC_BAS_DISC_PORT_SEG_LINGUA,
    QT_DOC_BAS_DISC_MATEMATICA,
    QT_DOC_BAS_DISC_CIENCIAS,
    QT_DOC_BAS_DISC_FISICA,
    QT_DOC_BAS_DISC_QUIMICA,
    QT_DOC_BAS_DISC_BIOLOGIA,
    QT_DOC_BAS_DISC_HISTORIA,
    QT_DOC_BAS_DISC_GEOGRAFIA,
    QT_DOC_BAS_DISC_SOCIOLOGIA,
    QT_DOC_BAS_DISC_FILOSOFIA,
    QT_DOC_BAS_DISC_EST_SOCIAIS,
    QT_DOC_BAS_DISC_EST_SOCIAIS_SOCI,
    QT_DOC_BAS_DISC_INFO_COMPUTACAO,
    QT_DOC_BAS_DISC_ENSINO_RELIGIOSO,
    QT_DOC_BAS_DISC_PROFISSIONA,
    QT_DOC_BAS_DISC_ESTAGIO_SUPER,
    QT_DOC_BAS_DISC_PEDAGOGICAS,
    QT_DOC_BAS_DISC_PROJETO_DE_VIDA,
    QT_DOC_BAS_DISC_OUTRAS,
QT_DOC_BAS_LIBRAS
  ) %>% 
  pivot_longer(
    cols = everything(),
    names_to = "disciplina",
    values_to = "quantidade"
  ) %>% 
  group_by(disciplina) %>% 
  summarise(
    total = sum(quantidade, na.rm = TRUE),
    .groups = "drop"
  ) %>% 
  mutate(
    percentual = scales::percent(total / sum(total))
  ) %>%
  arrange(desc(total))
