# =============================================================================
# ANÁLISE DESCRITIVA EXPLORATÓRIA — SAEB 2023 | PROFESSORES | REGIÃO SUL
# =============================================================================
# ANTES DE INICIAR SUA ANÁLISE, É PRECISO RODAR O PIPELINE.R
# PARA BAIXAR OS DADOS BRUTOS E CRIAR O BANCO DE DADOS

con <- DBI::dbConnect(duckdb::duckdb(), "data/db/saeb_sul_2023.duckdb", read_only = TRUE)


# =============================================================================
# 1. RECONHECIMENTO DA BASE
# =============================================================================
cli::cli_h1("1. RECONHECIMENTO DA BASE")

rows    <- DBI::dbGetQuery(con, "SELECT COUNT(*) AS n_linhas FROM professores")
columns <- DBI::dbGetQuery(con, "SELECT COUNT(*) AS n_colunas FROM information_schema.columns WHERE table_name = 'professores'")
knitr::kable(
  data.frame(linhas = rows$n_linhas, colunas = columns$n_colunas),
  caption = "Dimensões da base",
  format  = "simple"
)

cli::cli_h2("Primeiras linhas")
head_data <- DBI::dbGetQuery(con, "SELECT * FROM professores LIMIT 5")
knitr::kable(head_data, caption = "Amostra da base (5 linhas)", format = "simple")


# =============================================================================
# 2. QUALIDADE DOS DADOS
# =============================================================================
cli::cli_h1("2. QUALIDADE DOS DADOS")

cli::cli_h2("Preenchimento do questionário")
res_qualidade <- DBI::dbGetQuery(con, "
  SELECT
    IN_PREENCHIMENTO_QUESTIONARIO AS preenchimento,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
  FROM professores
  GROUP BY 1
  ORDER BY 1
")
knitr::kable(res_qualidade, caption = "Qualidade — preenchimento", format = "simple")

cli::cli_h2("Registros duplicados (mesmo professor em mais de uma turma)")
res_outra_turma <- DBI::dbGetQuery(con, "
  SELECT
    IN_PREENCHIMENTO_OUTRA_TURMA AS outra_turma,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
  FROM professores
  GROUP BY 1
  ORDER BY 1
")
knitr::kable(res_outra_turma, caption = "Preenchimento para outra turma", format = "simple")

cli::cli_h2("Distribuição por UF")
res_uf <- DBI::dbGetQuery(con, "
  SELECT
    ID_UF AS uf,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
  FROM professores
  WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
  GROUP BY 1
  ORDER BY 1
")
knitr::kable(res_uf, caption = "Distribuição por UF", format = "simple")

cli::cli_h2("Distribuição por rede (pública vs. privada)")
res_rede <- DBI::dbGetQuery(con, "
  SELECT
    IN_PUBLICA AS publica,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
  FROM professores
  WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
  GROUP BY 1
  ORDER BY 1
")
knitr::kable(res_rede, caption = "Rede escolar", format = "simple")

cli::cli_h2("Distribuição por localização (urbano/rural)")
res_loc <- DBI::dbGetQuery(con, "
  SELECT
    ID_LOCALIZACAO AS localizacao,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
  FROM professores
  WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
  GROUP BY 1
  ORDER BY 1
")
knitr::kable(res_loc, caption = "Localização", format = "simple")


# =============================================================================
# 3. PERFIL SOCIODEMOGRÁFICO
# =============================================================================
cli::cli_h1("3. PERFIL SOCIODEMOGRÁFICO")

cli::cli_h2("Sexo (Q001)")
res_sexo <- DBI::dbGetQuery(con, "
  SELECT
    TX_Q001 AS sexo,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
  FROM professores
  WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
  GROUP BY 1
  ORDER BY 2 DESC
")
knitr::kable(res_sexo, caption = "Sexo", format = "simple")

cli::cli_h2("Faixa etária (Q002)")
res_idade <- DBI::dbGetQuery(con, "
  SELECT
    TX_Q002 AS faixa_etaria,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
  FROM professores
  WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
  GROUP BY 1
  ORDER BY 1
")
knitr::kable(res_idade, caption = "Faixa etária", format = "simple")

cli::cli_h2("Cor ou raça (Q003)")
res_raca <- DBI::dbGetQuery(con, "
  SELECT
    TX_Q003 AS cor_raca,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
  FROM professores
  WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
  GROUP BY 1
  ORDER BY 2 DESC
")
knitr::kable(res_raca, caption = "Cor ou raça", format = "simple")

cli::cli_h2("Deficiência / TEA / Superdotação (Q004)")
res_def <- DBI::dbGetQuery(con, "
  SELECT
    TX_Q004 AS condicao,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
  FROM professores
  WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
  GROUP BY 1
  ORDER BY 2 DESC
")
knitr::kable(res_def, caption = "Deficiência / TEA / Superdotação", format = "simple")


# =============================================================================
# 4. PERFIL PROFISSIONAL
# =============================================================================
cli::cli_h1("4. PERFIL PROFISSIONAL")

cli::cli_h2("Nível de escolaridade (Q020)")
res_escol <- DBI::dbGetQuery(con, "
  SELECT
    TX_Q020 AS escolaridade,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
  FROM professores
  WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
  GROUP BY 1
  ORDER BY 2 DESC
")
knitr::kable(res_escol, caption = "Nível de escolaridade", format = "simple")

cli::cli_h2("Tempo de docência — total (Q048)")
res_tempo_total <- DBI::dbGetQuery(con, "
  SELECT
    TX_Q048 AS anos_docencia_total,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
  FROM professores
  WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
  GROUP BY 1
  ORDER BY 1
")
knitr::kable(res_tempo_total, caption = "Anos de docência (total)", format = "simple")

cli::cli_h2("Tempo de docência — nesta escola (Q049)")
res_tempo_escola <- DBI::dbGetQuery(con, "
  SELECT
    TX_Q049 AS anos_nesta_escola,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
  FROM professores
  WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
  GROUP BY 1
  ORDER BY 1
")
knitr::kable(res_tempo_escola, caption = "Anos nesta escola", format = "simple")

cli::cli_h2("Vínculo trabalhista (Q052)")
res_vinculo <- DBI::dbGetQuery(con, "
  SELECT
    TX_Q052 AS vinculo,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
  FROM professores
  WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
  GROUP BY 1
  ORDER BY 2 DESC
")
knitr::kable(res_vinculo, caption = "Vínculo trabalhista", format = "simple")

cli::cli_h2("Carga horária semanal total (Q053)")
res_ch <- DBI::dbGetQuery(con, "
  SELECT
    TX_Q053 AS carga_horaria,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
  FROM professores
  WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
  GROUP BY 1
  ORDER BY 1
")
knitr::kable(res_ch, caption = "Carga horária semanal", format = "simple")

cli::cli_h2("Faixa salarial bruta (Q054)")
res_salario <- DBI::dbGetQuery(con, "
  SELECT
    TX_Q054 AS faixa_salarial,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
  FROM professores
  WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
  GROUP BY 1
  ORDER BY 1
")
knitr::kable(res_salario, caption = "Faixa salarial bruta", format = "simple")

cli::cli_h2("Exerce outra atividade remunerada? (Q050)")
res_outra_atv <- DBI::dbGetQuery(con, "
  SELECT
    TX_Q050 AS outra_atividade,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
  FROM professores
  WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
  GROUP BY 1
  ORDER BY 2 DESC
")
knitr::kable(res_outra_atv, caption = "Outra atividade remunerada", format = "simple")

cli::cli_h2("Em quantas escolas trabalha? (Q051)")
res_n_escolas <- DBI::dbGetQuery(con, "
  SELECT
    TX_Q051 AS n_escolas,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
  FROM professores
  WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
  GROUP BY 1
  ORDER BY 1
")
knitr::kable(res_n_escolas, caption = "Número de escolas em que trabalha", format = "simple")


# =============================================================================
# 5. IDENTIDADE E SATISFAÇÃO DOCENTE
# =============================================================================
cli::cli_h1("5. IDENTIDADE E SATISFAÇÃO DOCENTE")

vars_satisfacao <- list(
  Q015 = list(col = "TX_Q015", label = "Tornar-me professor(a) foi realização de um sonho"),
  Q016 = list(col = "TX_Q016", label = "A profissão é valorizada pela sociedade"),
  Q017 = list(col = "TX_Q017", label = "Vantagens superam claramente as desvantagens"),
  Q018 = list(col = "TX_Q018", label = "Satisfeito(a) com o trabalho de professor(a)"),
  Q019 = list(col = "TX_Q019", label = "Tenho vontade de desistir da profissão")
)

for (q in names(vars_satisfacao)) {
  info <- vars_satisfacao[[q]]
  cli::cli_h2(paste0(q, " — ", info$label))
  res <- DBI::dbGetQuery(con, paste0("
    SELECT
      ", info$col, " AS resposta,
      COUNT(*) AS n,
      ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
    FROM professores
    WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
    GROUP BY 1
    ORDER BY 1
  "))
  print(knitr::kable(res, caption = info$label, format = "simple"))
}


# =============================================================================
# 6. FORMAÇÃO CONTINUADA
# =============================================================================
cli::cli_h1("6. FORMAÇÃO CONTINUADA")

vars_formacao <- list(
  Q021 = "TX_Q021", Q022 = "TX_Q022", Q023 = "TX_Q023",
  Q033 = "TX_Q033", Q034 = "TX_Q034", Q035 = "TX_Q035", Q036 = "TX_Q036"
)

labels_formacao <- list(
  Q021 = "Atividades formativas < 20h",
  Q022 = "Curso 20h–179h",
  Q023 = "Curso 180h–359h",
  Q033 = "Instituição/Secretaria financiou atividades",
  Q034 = "Participou de pós-graduação",
  Q035 = "Recebeu apoio da Secretaria para pós-grad.",
  Q036 = "Quem pagou a pós-graduação"
)

for (q in names(vars_formacao)) {
  cli::cli_h2(paste0(q, " — ", labels_formacao[[q]]))
  res <- DBI::dbGetQuery(con, paste0("
    SELECT
      ", vars_formacao[[q]], " AS resposta,
      COUNT(*) AS n,
      ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
    FROM professores
    WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
    GROUP BY 1
    ORDER BY 1
  "))
  print(knitr::kable(res, caption = labels_formacao[[q]], format = "simple"))
}


# =============================================================================
# 7. PRÁTICAS PEDAGÓGICAS (Q081–Q096) — escala Likert
# =============================================================================
cli::cli_h1("7. PRÁTICAS PEDAGÓGICAS")

vars_praticas <- list(
  Q081 = "TX_Q081", Q082 = "TX_Q082", Q083 = "TX_Q083",
  Q084 = "TX_Q084", Q085 = "TX_Q085", Q086 = "TX_Q086",
  Q087 = "TX_Q087", Q088 = "TX_Q088", Q089 = "TX_Q089",
  Q090 = "TX_Q090", Q091 = "TX_Q091", Q092 = "TX_Q092",
  Q093 = "TX_Q093", Q094 = "TX_Q094", Q095 = "TX_Q095",
  Q096 = "TX_Q096"
)

labels_praticas <- list(
  Q081 = "Propor dever de casa",
  Q082 = "Corrigir dever de casa com estudantes",
  Q083 = "Desenvolver trabalhos em grupo",
  Q084 = "Solicitar cópia de textos/atividades",
  Q085 = "Estimular expressão de opiniões e argumentos",
  Q086 = "Propor situações familiares/de interesse dos estudantes",
  Q087 = "Informar o que será ensinado no início do ano",
  Q088 = "Perguntar o que sabem ao iniciar novo conteúdo",
  Q089 = "Trazer temas do cotidiano para debate",
  Q090 = "Diversificar metodologias conforme dificuldades",
  Q091 = "Considerar resultados de avaliações como aprendizagem",
  Q092 = "Buscar estratégias para estudantes com menor desempenho",
  Q093 = "Abordar desigualdade racial",
  Q094 = "Abordar desigualdade de gênero",
  Q095 = "Abordar bullying e outras formas de violência",
  Q096 = "Abordar futuro profissional dos estudantes"
)

for (q in names(vars_praticas)) {
  cli::cli_h2(paste0(q, " — ", labels_praticas[[q]]))
  res <- DBI::dbGetQuery(con, paste0("
    SELECT
      ", vars_praticas[[q]], " AS resposta,
      COUNT(*) AS n,
      ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
    FROM professores
    WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
    GROUP BY 1
    ORDER BY 1
  "))
  print(knitr::kable(res, caption = labels_praticas[[q]], format = "simple"))
}


# =============================================================================
# 8. PERCEPÇÃO SOBRE OS ESTUDANTES (Q127–Q134)
# =============================================================================
cli::cli_h1("8. PERCEPÇÃO SOBRE OS ESTUDANTES")

vars_estudantes <- list(
  Q127 = list(col = "TX_Q127", label = "Respeitam os acordos em sala"),
  Q128 = list(col = "TX_Q128", label = "São assíduos(as)"),
  Q129 = list(col = "TX_Q129", label = "São respeitosos(as) comigo"),
  Q130 = list(col = "TX_Q130", label = "São respeitosos(as) com os colegas"),
  Q131 = list(col = "TX_Q131", label = "Expressam diferentes opiniões"),
  Q132 = list(col = "TX_Q132", label = "Se interessam pelo que foi ensinado"),
  Q133 = list(col = "TX_Q133", label = "Motivados(as) para aprender"),
  Q134 = list(col = "TX_Q134", label = "Capazes de concluir a Educação Básica")
)

for (q in names(vars_estudantes)) {
  info <- vars_estudantes[[q]]
  cli::cli_h2(paste0(q, " — ", info$label))
  res <- DBI::dbGetQuery(con, paste0("
    SELECT
      ", info$col, " AS resposta,
      COUNT(*) AS n,
      ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
    FROM professores
    WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
    GROUP BY 1
    ORDER BY 1
  "))
  print(knitr::kable(res, caption = info$label, format = "simple"))
}


# =============================================================================
# 9. CLIMA E VIOLÊNCIA ESCOLAR (Q135–Q147)
# =============================================================================
cli::cli_h1("9. CLIMA E VIOLÊNCIA ESCOLAR")

vars_violencia <- list(
  Q135 = "TX_Q135", Q136 = "TX_Q136", Q137 = "TX_Q137",
  Q138 = "TX_Q138", Q139 = "TX_Q139", Q140 = "TX_Q140",
  Q141 = "TX_Q141", Q142 = "TX_Q142", Q143 = "TX_Q143",
  Q144 = "TX_Q144", Q145 = "TX_Q145", Q146 = "TX_Q146",
  Q147 = "TX_Q147"
)

labels_violencia <- list(
  Q135 = "Atentado à vida",
  Q136 = "Lesão corporal",
  Q137 = "Roubo ou furto",
  Q138 = "Tráfico de drogas",
  Q139 = "Permanência sob efeito de álcool",
  Q140 = "Permanência sob efeito de drogas",
  Q141 = "Porte de arma",
  Q142 = "Assédio sexual",
  Q143 = "Discriminação",
  Q144 = "Bullying",
  Q145 = "Invasão do espaço escolar",
  Q146 = "Depredação do patrimônio (vandalismo)",
  Q147 = "Tiroteio ou bala perdida"
)

for (q in names(vars_violencia)) {
  cli::cli_h2(paste0(q, " — ", labels_violencia[[q]]))
  res <- DBI::dbGetQuery(con, paste0("
    SELECT
      ", vars_violencia[[q]], " AS resposta,
      COUNT(*) AS n,
      ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
    FROM professores
    WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
    GROUP BY 1
    ORDER BY 1
  "))
  print(knitr::kable(res, caption = labels_violencia[[q]], format = "simple"))
}


# =============================================================================
# 10. CRUZAMENTOS ANALÍTICOS CHAVE
# =============================================================================
cli::cli_h1("10. CRUZAMENTOS ANALÍTICOS CHAVE")

cli::cli_h2("Satisfação geral × Rede (pública vs. privada)")
res_sat_rede <- DBI::dbGetQuery(con, "
  SELECT
    IN_PUBLICA AS publica,
    TX_Q018 AS satisfacao,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY IN_PUBLICA), 1) AS pct
  FROM professores
  WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
  GROUP BY 1, 2
  ORDER BY 1, 2
")
knitr::kable(res_sat_rede, caption = "Satisfação × Rede", format = "simple")

cli::cli_h2("Satisfação geral × UF")
res_sat_uf <- DBI::dbGetQuery(con, "
  SELECT
    ID_UF AS uf,
    TX_Q018 AS satisfacao,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY ID_UF), 1) AS pct
  FROM professores
  WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
  GROUP BY 1, 2
  ORDER BY 1, 2
")
knitr::kable(res_sat_uf, caption = "Satisfação × UF", format = "simple")

cli::cli_h2("Vontade de desistir × Faixa salarial")
res_desistir_sal <- DBI::dbGetQuery(con, "
  SELECT
    TX_Q054 AS faixa_salarial,
    TX_Q019 AS vontade_desistir,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY TX_Q054), 1) AS pct
  FROM professores
  WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
  GROUP BY 1, 2
  ORDER BY 1, 2
")
knitr::kable(res_desistir_sal, caption = "Vontade de desistir × Faixa salarial", format = "simple")

cli::cli_h2("Salário × UF")
res_sal_uf <- DBI::dbGetQuery(con, "
  SELECT
    ID_UF AS uf,
    TX_Q054 AS faixa_salarial,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY ID_UF), 1) AS pct
  FROM professores
  WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
  GROUP BY 1, 2
  ORDER BY 1, 2
")
knitr::kable(res_sal_uf, caption = "Faixa salarial × UF", format = "simple")

cli::cli_h2("Bullying reportado × Localização (urbano/rural)")
res_bull_loc <- DBI::dbGetQuery(con, "
  SELECT
    ID_LOCALIZACAO AS localizacao,
    TX_Q144 AS bullying,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY ID_LOCALIZACAO), 1) AS pct
  FROM professores
  WHERE IN_PREENCHIMENTO_QUESTIONARIO = 1
  GROUP BY 1, 2
  ORDER BY 1, 2
")
knitr::kable(res_bull_loc, caption = "Bullying × Localização", format = "simple")


# =============================================================================
# FIM DA ANÁLISE
# =============================================================================
DBI::dbDisconnect(con, shutdown = TRUE)
cli::cli_alert_success("Análise concluída e conexão encerrada.")