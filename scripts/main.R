# ANTES DE INICIAR SUA ANALISE, É PRECISO RODAR O PIPELINE.R
# PARA BAIXAR OS DADOS BRUTOS E CRIAR O BANCO DE DADOS

con <- DBI::dbConnect(duckdb::duckdb(), "data/db/saeb_sul_2023.duckdb", read_only = TRUE)

DBI::dbListFields(con, "alunos")
DBI::dbListFields(con, "escolas")
DBI::dbListFields(con, "professores")

DBI::dbExecute(con, "DROP VIEW IF EXISTS base_modelagem")
DBI::dbExecute(con, "
  CREATE VIEW base_modelagem AS
  SELECT 
    a.id_aluno,
    a.turma,
    p.nome AS nome_professor,
    e.nome AS nome_escola
  FROM alunos a
  LEFT JOIN professores p 
    ON a.ID_ESCOLA = p.ID_ESCOLA
  LEFT JOIN escolas e 
    ON a.ID_ESCOLA = e.ID_ESCOLA
")

DBI::dbGetQuery(con, "SELECT * FROM base_modelagem")
DBI::dbDisconnect(con, shutdown = TRUE)
