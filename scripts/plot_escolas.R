library(dplyr)
library(ggplot2)
library(geobr)

df <- readr::read_csv("data/processed/escolas_sul.csv")

# Obter os limites do estado do Paraná
pr_states <- geobr::read_state(code_state = "PR", year = 2020)

# Obter os limites do estado do Rio Grande do Sul
rs_states <- geobr::read_state(code_state = "RS", year = 2020)

# Obter os limites do estado de Santa Catarina
sc_states <- geobr::read_state(code_state = "SC", year = 2020)

# Unir os estados
states <- rbind(pr_states, rs_states, sc_states)

df %>%
  dplyr::filter(TP_SITUACAO_FUNCIONAMENTO == 1 & TP_DEPENDENCIA == 1) %>%
  dplyr::mutate(TP_LOCALIZACAO = case_when(
    TP_LOCALIZACAO == 1 ~ "Urbana",
    TP_LOCALIZACAO == 2 ~ "Rural",
    TRUE ~ as.character(TP_LOCALIZACAO)
  )) %>%
  ggplot2::ggplot() + 
  ggplot2::geom_sf(data = states, fill = "white", color = "black") + 
  ggplot2::geom_point(aes(x = LONGITUDE, y = LATITUDE, color = TP_LOCALIZACAO), alpha = 0.5) + 
  ggplot2::theme_minimal() + 
  ggplot2::labs(title = "Escolas Federais em Atividade na Região Sul", subtitle = "Censo Escolar 2025")


df %>%
  dplyr::filter(TP_SITUACAO_FUNCIONAMENTO == 1 & TP_DEPENDENCIA == 2) %>%
  dplyr::mutate(TP_LOCALIZACAO = case_when(
    TP_LOCALIZACAO == 1 ~ "Urbana",
    TP_LOCALIZACAO == 2 ~ "Rural",
    TRUE ~ as.character(TP_LOCALIZACAO)
  )) %>%
  ggplot2::ggplot() + 
  ggplot2::geom_sf(data = states, fill = "white", color = "black") + 
  ggplot2::geom_point(aes(x = LONGITUDE, y = LATITUDE, color = TP_LOCALIZACAO), alpha = 0.5) + 
  ggplot2::theme_minimal() + 
  ggplot2::labs(title = "Escolas Estaduais em Atividade na Região Sul", subtitle = "Censo Escolar 2025")


df %>%
  dplyr::filter(TP_SITUACAO_FUNCIONAMENTO == 1 & TP_DEPENDENCIA == 3) %>%
  dplyr::mutate(TP_LOCALIZACAO = case_when(
    TP_LOCALIZACAO == 1 ~ "Urbana",
    TP_LOCALIZACAO == 2 ~ "Rural",
    TRUE ~ as.character(TP_LOCALIZACAO)
  )) %>%
  ggplot2::ggplot() + 
  ggplot2::geom_sf(data = states, fill = "white", color = "black") + 
  ggplot2::geom_point(aes(x = LONGITUDE, y = LATITUDE, color = TP_LOCALIZACAO), alpha = 0.5) + 
  ggplot2::theme_minimal() + 
  ggplot2::labs(title = "Escolas Municipais em Atividade na Região Sul", subtitle = "Censo Escolar 2025")


df %>%
  dplyr::filter(TP_SITUACAO_FUNCIONAMENTO == 1 & TP_DEPENDENCIA == 4) %>%
  dplyr::mutate(TP_LOCALIZACAO = case_when(
    TP_LOCALIZACAO == 1 ~ "Urbana",
    TP_LOCALIZACAO == 2 ~ "Rural",
    TRUE ~ as.character(TP_LOCALIZACAO)
  )) %>%
  ggplot2::ggplot() + 
  ggplot2::geom_sf(data = states, fill = "white", color = "black") + 
  ggplot2::geom_point(aes(x = LONGITUDE, y = LATITUDE, color = TP_LOCALIZACAO), alpha = 0.5) + 
  ggplot2::theme_minimal() + 
  ggplot2::labs(title = "Escolas Privadas em Atividade na Região Sul", subtitle = "Censo Escolar 2025")
