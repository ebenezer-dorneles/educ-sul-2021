# Censo Escolar 2025

O objetivo deste projeto é analisar os dados do Censo Escolar 2025 da região Sul do Brasil.

## Estrutura do projeto
- `renv/` - Diretório que contém as dependências do projeto.

- `R/` - Diretório que contém os scripts para análise dos dados.
  - `main.R` - Script principal para baixar os dados do Censo Escolar 2025.
  - `escolas.R` - Script para análise das escolas.
  - `plot_escolas.R` - Script para plotar as escolas.

- `data/` - Diretório que contém os dados do Censo Escolar 2025.
  - `raw/` - Dados brutos do Censo Escolar 2025.
  - `processed/` - Dados processados do Censo Escolar 2025.
  
- `scripts/` - Diretório que contém os scripts para análise dos dados.
  - `main.R` - Script principal para baixar os dados do Censo Escolar 2025.
  - `escolas.R` - Script para análise das escolas.
  - `plot_escolas.R` - Script para plotar as escolas.

## Instalação

- Instalar as dependências do projeto:

```bash
# Instalar as dependências do projeto
renv::restore()
```

## Execução
1. Baixar os dados do Censo Escolar 2025:

```bash
# Baixar os dados do Censo Escolar 2025
Rscript scripts/main.R
```

2. Executar os scripts para análise  das escolas:

```bash
# Análise das escolas
Rscript scripts/escolas.R

# Plot das escolas
Rscript scripts/plot_escolas.R
```
