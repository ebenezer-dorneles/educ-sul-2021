if(! require("pacman")){
  install.packages("pacman")
  library(pacman)
}

pacman::p_load(
  downloader, # Para baixar arquivos da internet
  readr,      # Para ler arquivos CSV
  dplyr,      # Para manipulação de dados
  ggplot2,    # Para visualização de dados
  tidyr,      # Para limpeza e organização de dados
  stringr,    # Para manipulação de strings
  dotenv,     # Para carregar variáveis de ambiente
  geobr       # Para obter dados geográficos
)
