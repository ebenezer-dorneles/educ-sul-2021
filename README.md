# Ambiente Escolar e Desempenho Acadêmico no Ensino Médio
### Uma análise multinível dos dados do SAEB 2023 — Região Sul do Brasil

> Monografia de Especialização em Estatística e Modelagem Quantitativa  
> Dados: SAEB 2023 (INEP/MEC) · Região Sul (PR, SC, RS) · Ensino Médio

---

## Resumo

Este projeto investiga se a **percepção de ambiente escolar insalubre** — captada separadamente por alunos e professores — está associada ao **desempenho em Língua Portuguesa e Matemática** no SAEB 2023, após controlar pelo nível socioeconômico individual e características das escolas.

A motivação teórica parte da literatura sobre **carga alostática** (Evans & Schamberg, 2009): ambientes escolares marcados por violência, insegurança e clima relacional deteriorado podem direcionar energia cognitiva para estratégias de sobrevivência e manejo do estresse, em detrimento do aprendizado. Isso significa que fatores estruturais e institucionais — não apenas a formação docente — são determinantes relevantes do desempenho escolar.

---

## Estrutura do Repositório

```
.
├── data/
│   └── db/
│       └── saeb_sul_2023.duckdb      # Banco de dados (gerado pelo pipeline)
├── scripts/
│   ├── pipeline.R                    # Download e ingestão dos microdados brutos
│   ├── main.R                        # Script principal de análise
│   └── diagnostico_nas.R             # Script auxiliar de diagnóstico
├── outputs/
│   ├── fig_01_distribuicao_proficiencia.png
│   ├── fig_02_prof_por_inse.png
│   └── fig_03_coeficientes_m3_lp.png
└── README.md
```

---

## Dados

Os microdados são públicos e disponibilizados pelo [INEP](https://www.gov.br/inep/pt-br/areas-de-atuacao/avaliacao-e-exames-educacionais/saeb/resultados).

| Tabela | Fonte | N (Região Sul) |
|---|---|---|
| `alunos` | TS_ALUNO_34EM.csv | ~195 mil |
| `professores` | TS_PROFESSOR.csv | ~45 mil |
| `escolas` | TS_ESCOLA.csv | ~10 mil |

O banco DuckDB é gerado pelo `pipeline.R`, que baixa os arquivos brutos, filtra a Região Sul (`ID_REGIAO == 4`, `ID_UF ∈ {41, 42, 43}`) e persiste as três tabelas localmente.

---

## Metodologia

### Construção dos índices de percepção de ambiente

Três índices foram construídos via **Análise Fatorial Exploratória (AFE)** com estimação ML:

| Índice | Fonte | Itens | α de Cronbach |
|---|---|---|---|
| Percepção de ambiente (aluno) | Questionário do aluno | Q23a–i, Q22f (8 itens) | 0,77 |
| Violência escolar | Questionário do professor (TX_Q135–Q147) | 12 itens | 0,85 |
| Clima relacional | Questionário do professor (TX_Q120–Q130) | 7 itens | 0,77 |

Os índices dos professores são **agregados por escola** (média) antes de entrar no modelo, representando a percepção coletiva do corpo docente sobre o ambiente.

### Modelo multinível (HLM)

Os alunos estão aninhados em escolas, tornando o **Hierarchical Linear Model** a abordagem adequada (Raudenbush & Bryk, 2002). A sequência de modelos estimada:

```
M0  Modelo nulo                     → ICC (justifica o HLM)
M1  + Controles individuais (N1)    → linha de base
M2  + Índice de ambiente do aluno   → efeito bruto da variável de interesse
M3  + Variáveis de escola (N2/N3)   → efeito líquido após controles institucionais
M4  + Slope aleatório               → o efeito varia entre escolas?
M5  Sub-índices separados (F1 e F2) → análise de sensibilidade
```

**Variável dependente:** Proficiência em LP e MT na escala SAEB (`PROFICIENCIA_LP_SAEB`, `PROFICIENCIA_MT_SAEB`)

**Hipóteses centrais:**

- **H1** — A percepção de ambiente insalubre pelo aluno está negativamente associada à proficiência, após controlar pelo INSE e características da escola.
- **H2** — O índice de violência escolar agregado dos professores tem efeito negativo adicional sobre o desempenho, além do efeito individual do aluno.
- **H3** — O efeito do ambiente percebido pelo aluno varia entre escolas (slope aleatório significativo), sugerindo moderação por fatores institucionais.

### Variáveis de controle

**Nível 1 — Aluno**

| Variável | Descrição |
|---|---|
| `inse` | Índice de Nível Socioeconômico (1–8) |
| `sexo` | Feminino = 1 |
| `raca_branca` | Autodeclaração |
| `reprovado` | Já foi reprovado |
| `abandonou` | Já abandonou a escola |
| `trabalha` | Horas de trabalho fora de casa |
| `escol_mae` | Escolaridade da mãe |
| `eng_pais` | Engajamento dos pais com a escola |

**Nível 2/3 — Escola**

| Variável | Descrição |
|---|---|
| `inse_escola` | INSE médio da escola (I–VIII → 1–8) |
| `publica` | Dependência administrativa |
| `rural` | Localização urbana/rural |
| `form_doc` | % docentes com formação adequada |
| `ln_n_alunos` | Porte da escola (log de matriculados) |
| `idx_violencia_escola` | Índice de violência (prof. agregado) |
| `idx_clima_escola` | Índice de clima relacional (prof. agregado) |

---

## Resultados Preliminares

| Indicador | LP | MT |
|---|---|---|
| ICC (modelo nulo) | 0,111 | 0,154 |
| Variância entre escolas | 11,1% | 15,4% |
| α do índice (aluno) | 0,77 | — |
| α do índice (violência prof.) | 0,85 | — |
| α do índice (clima prof.) | 0,77 | — |

O ICC acima de 10% em ambas as disciplinas justifica plenamente o uso de HLM — mais de 1/10 da variância de proficiência está associada a diferenças entre escolas, não entre alunos.

---

## Reprodutibilidade

### Pré-requisitos

- R ≥ 4.3
- Docker (opcional, mas recomendado para ambiente reprodutível)

### Pacotes R necessários

```r
install.packages(c(
  "DBI", "duckdb", "dplyr", "tidyr", "ggplot2",
  "psych", "lme4", "lmerTest", "performance",
  "scales", "broom.mixed"
))
```

### Execução

```bash
# 1. Gerar o banco de dados (baixa microdados do INEP)
Rscript scripts/pipeline.R

# 2. Rodar a análise completa
Rscript scripts/main.R

# Com Docker
docker exec -it r-base Rscript scripts/main.R
```

---

## Referências Principais

### Metodologia estatística
- Raudenbush, S. W., & Bryk, A. S. (2002). *Hierarchical Linear Models* (2ª ed.). Sage.
- Barbosa, M. E., & Fernandes, C. (2000). Modelo multinível: uma aplicação a dados de avaliação educacional. *Estudos em Avaliação Educacional*, 22. https://doi.org/10.18222/eae02220002220
- Ferrão, M. E. (2003). *Introdução aos modelos de regressão multinível em educação.* Komedi.

### Clima escolar e desempenho
- Maxwell, B., et al. (2017). The impact of school climate and school identification on academic achievement: multilevel modeling with student and teacher data. *Frontiers in Psychology*, 8, 2069. https://doi.org/10.3389/fpsyg.2017.02069
- Ma, X., & Klinger, D. A. (2000). Hierarchical linear modelling of student and school effects on academic achievement. *Canadian Journal of Education*, 25(1), 41–55.
- Demirtas-Zorbaz, S., Akin-Arikan, C., & Terzi, R. (2021). Does school climate that includes students' views deliver academic achievement? *School Effectiveness and School Improvement*, 32(4), 543–563.

### Violência escolar e SAEB no Brasil
- Faria, A. C. L. (2020). *Violência nas escolas e desempenho dos estudantes do 3º ano do ensino médio no Brasil.* Dissertação (Mestrado) — UFV.
- Oliveira, R. V., & Ferreira, D. (2013). Violência e desempenho dos alunos nas escolas brasileiras: uma análise a partir do SAEB 2011. *Revista Econômica*, 15(1).
- Duarte, R. (2017). Influência da violência dentro e fora da escola na proficiência escolar dos alunos da cidade do Recife. *Revista Brasileira de Segurança Pública.*

### Base teórica: estresse e cognição
- Evans, G. W., & Schamberg, M. A. (2009). Childhood poverty, chronic stress, and adult working memory. *PNAS*, 106(16), 6545–6549. https://doi.org/10.1073/pnas.0811910106
- D'Amico, D., et al. (2020). The association between allostatic load and cognitive function: A systematic and meta-analytic review. *Psychoneuroendocrinology*, 122, 104855.

---

## Licença

Os microdados do SAEB são públicos e de livre uso, disponibilizados pelo INEP sob a [Lei de Acesso à Informação (Lei nº 12.527/2011)](http://www.planalto.gov.br/ccivil_03/_ato2011-2014/2011/lei/l12527.htm). O código deste repositório está disponível sob a licença [MIT](LICENSE).

---

*Especialização em Estatística e Modelagem Quantitativa · 2025*