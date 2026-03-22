source("scripts/main.R")

library(dplyr)
library(stringr)
library(readr)

df_escolas_filtered <- data_censo_2025$get_table("Tabela_Escola_2025.csv") %>%
  filter(NO_REGIAO == "Sul")

dplyr::glimpse(df_escolas_filtered)

# Quantas escolas tem em cada estado no sul do Brasil?
df_escolas_filtered %>%
  group_by(NO_UF) %>%
  summarise(total_escolas = n()) %>%
  mutate(percentual = scales::percent(total_escolas / sum(total_escolas))) %>%
  arrange(desc(total_escolas))

# Quantas escolas tem em cada estado no sul do Brasil por situação de funcionamento?
df_escolas_filtered %>%
  group_by(NO_UF, TP_SITUACAO_FUNCIONAMENTO) %>%
  summarise(total_escolas = n()) %>%
  mutate(TP_SITUACAO_FUNCIONAMENTO = case_when(
    TP_SITUACAO_FUNCIONAMENTO == 1 ~ "Em atividade",
    TP_SITUACAO_FUNCIONAMENTO == 2 ~ "Paralisada",
    TP_SITUACAO_FUNCIONAMENTO == 3 ~ "Extinta",
    TRUE ~ as.character(TP_SITUACAO_FUNCIONAMENTO)
  )) %>%
  mutate(percentual = scales::percent(total_escolas / sum(total_escolas))) %>%
  arrange(desc(total_escolas))

# Quantas escolas em atividade tem em cada estado no sul do Brasil por dependencia administrativa?
df_escolas_filtered %>%
  filter(TP_SITUACAO_FUNCIONAMENTO == 1) %>%
  group_by(NO_UF, TP_DEPENDENCIA) %>%
  summarise(total_escolas = n()) %>%
  mutate(TP_DEPENDENCIA = case_when(
    TP_DEPENDENCIA == 1 ~ "Federal",
    TP_DEPENDENCIA == 2 ~ "Estadual",
    TP_DEPENDENCIA == 3 ~ "Municipal",
    TP_DEPENDENCIA == 4 ~ "Privada",
    TRUE ~ as.character(TP_DEPENDENCIA)
  )) %>%
  mutate(percentual = scales::percent(total_escolas / sum(total_escolas))) %>%
  arrange(desc(total_escolas))

#Quantas ecolas públicas em atividade tem em cada estado no sul do Brasil?
df_escolas_filtered %>%
  filter(TP_SITUACAO_FUNCIONAMENTO == 1) %>%
  mutate(TP_DEPENDENCIA = case_when(
    TP_DEPENDENCIA == 1 | TP_DEPENDENCIA == 2 | TP_DEPENDENCIA == 3 ~ "Pública",
    TRUE ~ "Privada"
  )) %>%
  group_by(NO_UF, TP_DEPENDENCIA) %>%
  summarise(total_escolas = n()) %>%
  mutate(percentual = scales::percent(total_escolas / sum(total_escolas))) %>%
  arrange(desc(total_escolas))

# Quantas escolas públicas em atividade tem em cada estado no sul do Brasil por localização?
df_escolas_filtered %>%
  filter(TP_SITUACAO_FUNCIONAMENTO == 1) %>%
  filter(TP_DEPENDENCIA == 1 | TP_DEPENDENCIA == 2 | TP_DEPENDENCIA == 3) %>%
  group_by(NO_UF, TP_LOCALIZACAO) %>%
  summarise(total_escolas = n()) %>%
  mutate(TP_LOCALIZACAO = case_when(
    TP_LOCALIZACAO == 1 ~ "Urbana",
    TP_LOCALIZACAO == 2 ~ "Rural",
    TRUE ~ as.character(TP_LOCALIZACAO)
  )) %>%
  mutate(percentual = scales::percent(total_escolas / sum(total_escolas))) %>%
  arrange(desc(total_escolas))

df_escolas_filtered %>%
  readr::write_csv("data/processed/escolas_sul.csv")

df_escolas_filtered %>%
  dplyr::select(CO_ENTIDADE, NO_ENTIDADE, NO_MUNICIPIO, NO_UF) %>%
  readr::write_csv("data/processed/identificacao_escolas_sul.csv")



