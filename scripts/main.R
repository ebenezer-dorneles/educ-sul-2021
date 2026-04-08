# ANTES DE INICIAR SUA ANALISE, É PRECISO RODAR O PIPELINE.R
# PARA BAIXAR OS DADOS BRUTOS E CRIAR O BANCO DE DADOS


cli::cli_h1('')

cli::cli_h2("RECONHECENDO A BASE DE DADOS")
con <- DBI::dbConnect(duckdb::duckdb(), "data/db/saeb_sul_2023.duckdb", read_only = TRUE)

DBI::dbGetQuery(con, "SELECT COUNT(*) AS n_linhas FROM professores")
DBI::dbGetQuery(con, "SELECT COUNT(*) AS n_colunas FROM information_schema.columns WHERE table_name = 'professores'")

cli::cli_h1('')

cli::cli_h2("QUALIDADE")
DBI::dbGetQuery(con, "
  SELECT IN_PREENCHIMENTO_QUESTIONARIO, COUNT(*) AS n
  FROM professores
  GROUP BY 1
")

cli::cli_h1('')

cli::cli_h2("PERFIL SOCIODEMOGRÁFICO")
DBI::dbGetQuery(con, "
  SELECT TX_Q001 AS sexo, COUNT(*) AS n,
         ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
  FROM professores
  WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
  GROUP BY 1
  ORDER BY 2 DESC
")

cli::cli_h1('')


DBI::dbDisconnect(con, shutdown = TRUE)
