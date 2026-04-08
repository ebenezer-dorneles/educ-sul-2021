# ANTES DE INICIAR SUA ANALISE, É PRECISO RODAR O PIPELINE.R
# PARA BAIXAR OS DADOS BRUTOS E CRIAR O BANCO DE DADOS


con <- DBI::dbConnect(duckdb::duckdb(), "data/db/saeb_sul_2023.duckdb", read_only = TRUE)

rows <- DBI::dbGetQuery(con, "SELECT COUNT(*) AS n_linhas FROM professores")
columns <- DBI::dbGetQuery(con, "SELECT COUNT(*) AS n_colunas FROM information_schema.columns WHERE table_name = 'professores'")
knitr::kable(data.frame(linhas = rows, colunas = columns), caption = "Informações da base de dados", format = "pipe")

cli::cli_h1('')
#---------------------------------------------------------------------------------------------------------------------------------

res_qualidade <- DBI::dbGetQuery(con, "
  SELECT IN_PREENCHIMENTO_QUESTIONARIO, COUNT(*) AS n
  FROM professores
  GROUP BY 1
")
knitr::kable(res_qualidade, caption = "Qualidade", format = "pipe")

cli::cli_h1('')
#---------------------------------------------------------------------------------------------------------------------------------

res_perfil <- DBI::dbGetQuery(con, "
  SELECT TX_Q001 AS sexo, COUNT(*) AS n,
         ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
  FROM professores
  WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
  GROUP BY 1
  ORDER BY 2 DESC
")
knitr::kable(res_perfil, caption = "Perfil sociodemográfico", format = "pipe")


cli::cli_h1('')
#---------------------------------------------------------------------------------------------------------------------------------


DBI::dbDisconnect(con, shutdown = TRUE)
