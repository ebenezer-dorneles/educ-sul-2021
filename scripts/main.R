# =============================================================================
# MONOGRAFIA — AMBIENTE ESCOLAR E DESEMPENHO ACADÊMICO
# SAEB 2023 | REGIÃO SUL | ENSINO MÉDIO
# v3 — Correções:
#   - Proficiência na escala SAEB (200-400) via PROFICIENCIA_LP_SAEB
#   - Remoção de `capital` (colinear com ID_AREA / rural → rank deficient)
#   - Banco HLM único com drop_na em TODAS as variáveis do modelo completo,
#     garantindo N idêntico em todos os modelos para anova()
# =============================================================================

# -----------------------------------------------------------------------------
# 0. PACOTES E CONEXÃO
# -----------------------------------------------------------------------------

pkgs <- c("DBI", "duckdb", "dplyr", "tidyr", "ggplot2",
          "psych", "lme4", "lmerTest", "performance",
          "scales", "broom.mixed")

invisible(lapply(pkgs, function(p) {
  if (!require(p, character.only = TRUE, quietly = TRUE))
    install.packages(p, quiet = TRUE)
  library(p, character.only = TRUE)
}))

dir.create("outputs", showWarnings = FALSE)

con <- DBI::dbConnect(
  duckdb::duckdb(),
  "data/db/saeb_sul_2023.duckdb",
  read_only = TRUE
)

# -----------------------------------------------------------------------------
# 1. CARREGAMENTO E FILTROS
# -----------------------------------------------------------------------------

alunos_raw <- tbl(con, "alunos") |>
  filter(
    ID_REGIAO == 4,
    ID_UF %in% c(41L, 42L, 43L),
    IN_PRESENCA_LP == 1,
    IN_PRESENCA_MT == 1,
    IN_PROFICIENCIA_LP == 1,
    IN_PREENCHIMENTO_QUESTIONARIO == 1
  ) |>
  collect()

professores_raw <- tbl(con, "professores") |>
  filter(
    ID_REGIAO == 4,
    ID_UF %in% c(41L, 42L, 43L),
    IN_PREENCHIMENTO_QUESTIONARIO == 1
  ) |>
  collect()

escolas_raw <- tbl(con, "escolas") |>
  filter(
    ID_REGIAO == 4,
    ID_UF %in% c(41L, 42L, 43L)
  ) |>
  collect()

DBI::dbDisconnect(con, shutdown = TRUE)

cat("Alunos:     ", nrow(alunos_raw),     "\n")
cat("Professores:", nrow(professores_raw), "\n")
cat("Escolas:    ", nrow(escolas_raw),     "\n")


# -----------------------------------------------------------------------------
# 2. FUNÇÕES AUXILIARES
# -----------------------------------------------------------------------------

letra_para_num <- function(x) {
  dplyr::recode(as.character(x),
    "A" = 1L, "B" = 2L, "C" = 3L, "D" = 4L,
    .default = NA_integer_
  )
}

inverter <- function(x, max = 4L) (max + 1L) - x

nivel_para_num <- function(x) {
  dplyr::recode(trimws(as.character(x)),
    "Nível I"    = 1L, "Nivel I"    = 1L,
    "Nível II"   = 2L, "Nivel II"   = 2L,
    "Nível III"  = 3L, "Nivel III"  = 3L,
    "Nível IV"   = 4L, "Nivel IV"   = 4L,
    "Nível V"    = 5L, "Nivel V"    = 5L,
    "Nível VI"   = 6L, "Nivel VI"   = 6L,
    "Nível VII"  = 7L, "Nivel VII"  = 7L,
    "Nível VIII" = 8L, "Nivel VIII" = 8L,
    .default = NA_integer_
  )
}


# -----------------------------------------------------------------------------
# 3. RECODIFICAÇÃO
# -----------------------------------------------------------------------------

# --- 3.1 Alunos ---------------------------------------------------------------
alunos <- alunos_raw |>
  mutate(
    escola = as.character(ID_ESCOLA),
    uf     = factor(ID_UF, levels = c(41,42,43), labels = c("PR","SC","RS")),

    # CORREÇÃO: usar escala SAEB (200-400) em vez da escala 0-1
    prof_lp = as.numeric(PROFICIENCIA_LP_SAEB),
    prof_mt = as.numeric(PROFICIENCIA_MT_SAEB),

    inse        = as.numeric(NU_TIPO_NIVEL_INSE),
    sexo        = ifelse(TX_RESP_Q01 == "B", 1L, 0L),
    raca_branca = ifelse(TX_RESP_Q04 == "A", 1L, 0L),
    reprovado   = ifelse(TX_RESP_Q19 == "B", 1L, 0L),
    abandonou   = ifelse(TX_RESP_Q20 == "B", 1L, 0L),
    trabalha    = letra_para_num(TX_RESP_Q21d),
    escol_mae   = letra_para_num(TX_RESP_Q08),
    eng_pais    = rowMeans(
      cbind(letra_para_num(TX_RESP_Q10b),
            letra_para_num(TX_RESP_Q10c),
            letra_para_num(TX_RESP_Q10e),
            letra_para_num(TX_RESP_Q10f)),
      na.rm = TRUE
    ),

    # Itens de percepção de ambiente (aluno)
    amb_a_seguro     = letra_para_num(TX_RESP_Q23d),
    amb_a_espaco_op  = letra_para_num(TX_RESP_Q23c),
    amb_a_prof_capaz = letra_para_num(TX_RESP_Q23h),
    amb_a_prof_motiv = letra_para_num(TX_RESP_Q23i),
    amb_a_bullying   = letra_para_num(TX_RESP_Q22f),
    amb_a_motiv      = letra_para_num(TX_RESP_Q23b),
    amb_a_interesse  = letra_para_num(TX_RESP_Q23a),
    amb_a_discordar  = letra_para_num(TX_RESP_Q23e)
  )

# --- 3.2 Professores ----------------------------------------------------------
violencia_vars <- c("TX_Q135","TX_Q136","TX_Q137","TX_Q138",
                    "TX_Q139","TX_Q140","TX_Q141","TX_Q142",
                    "TX_Q143","TX_Q144","TX_Q145","TX_Q146","TX_Q147")
clima_vars <- c("TX_Q127","TX_Q128","TX_Q129","TX_Q130",
                "TX_Q120","TX_Q122","TX_Q123")

professores <- professores_raw |>
  mutate(
    escola = as.character(ID_ESCOLA),
    across(all_of(c(violencia_vars, clima_vars)), letra_para_num),
    across(all_of(violencia_vars), ~inverter(.x, max = 4L)),
    formacao_prof = letra_para_num(TX_Q020),
    sexo_prof     = ifelse(TX_Q001 == "B", 1L, 0L)
  )

# --- 3.3 Escolas --------------------------------------------------------------
# CORREÇÃO: removida variável `capital` — colinear com ID_AREA/rural
# (causa rank deficiency nos modelos)
escolas <- escolas_raw |>
  mutate(
    escola      = as.character(ID_ESCOLA),
    uf          = factor(ID_UF, levels = c(41,42,43), labels = c("PR","SC","RS")),
    publica     = as.integer(IN_PUBLICA),
    rural       = ifelse(ID_LOCALIZACAO == 2, 1L, 0L),
    # REMOVIDO: capital (redundante com ID_AREA que já entra via UF/rural)
    inse_escola = nivel_para_num(NIVEL_SOCIO_ECONOMICO),
    form_doc    = as.numeric(PC_FORMACAO_DOCENTE_MEDIO),
    n_alunos    = as.numeric(NU_MATRICULADOS_CENSO_EM),
    tx_part     = as.numeric(TAXA_PARTICIPACAO_EM),
    media_lp_escola = as.numeric(MEDIA_EM_LP),
    media_mt_escola = as.numeric(MEDIA_EM_MT)
  )


# -----------------------------------------------------------------------------
# 4. ÍNDICES DE PERCEPÇÃO DE AMBIENTE (AFE)
# -----------------------------------------------------------------------------

cat("\n=== AFE: Percepção de ambiente — Aluno ===\n")

itens_aluno <- alunos |>
  select(starts_with("amb_a_")) |>
  drop_na()

cat("KMO:", round(psych::KMO(itens_aluno)$MSA, 3), "\n")

# Análise paralela
fa_par <- psych::fa.parallel(itens_aluno, fm = "ml", fa = "fa",
                              plot = FALSE, n.iter = 50)
cat("Fatores sugeridos:", fa_par$nfact, "\n")
cat("Nota: análise paralela com N grande tende a supersuguerir fatores.\n")
cat("Estrutura de 2 fatores interpretável:\n")
cat("  F1 = Relação professor-aluno (Q23h, Q23i, Q23b, Q23a)\n")
cat("  F2 = Segurança e clima da escola (Q23d, Q23c, Q23e, Q22f)\n")
cat("Decisão: usar 2 sub-índices + índice geral como sensibilidade.\n\n")

# AFE 1 fator
afe_1f <- psych::fa(itens_aluno, nfactors = 1, fm = "ml", rotate = "none")
cat("Cargas — 1 fator:\n")
print(afe_1f$loadings, cutoff = 0.2)

# AFE 2 fatores
afe_2f <- psych::fa(itens_aluno, nfactors = 2, fm = "ml", rotate = "oblimin")
cat("\nCargas — 2 fatores (oblimin):\n")
print(afe_2f$loadings, cutoff = 0.2)
cat("Correlação entre fatores:", round(afe_2f$Phi[1,2], 3), "\n")

cat("\nAlpha geral:", round(psych::alpha(itens_aluno)$total$raw_alpha, 3), "\n")

# Sub-índices baseados na estrutura de 2 fatores
itens_f1 <- c("amb_a_prof_capaz","amb_a_prof_motiv","amb_a_motiv","amb_a_interesse")
itens_f2 <- c("amb_a_seguro","amb_a_espaco_op","amb_a_discordar","amb_a_bullying")

cat("Alpha F1 (relação prof-aluno):",
    round(psych::alpha(itens_aluno[itens_f1])$total$raw_alpha, 3), "\n")
cat("Alpha F2 (segurança/clima):",
    round(psych::alpha(itens_aluno[itens_f2])$total$raw_alpha, 3), "\n")

alunos <- alunos |>
  mutate(
    idx_amb_aluno = rowMeans(pick(all_of(c(itens_f1, itens_f2))), na.rm = TRUE),
    idx_f1_prof   = rowMeans(pick(all_of(itens_f1)), na.rm = TRUE),
    idx_f2_segur  = rowMeans(pick(all_of(itens_f2)), na.rm = TRUE)
  )

# --- Índices do professor -----------------------------------------------------
cat("\n=== AFE: Violência escolar — Professor ===\n")
itens_viol  <- professores |> select(all_of(violencia_vars)) |> drop_na()
afe_viol    <- psych::fa(itens_viol, nfactors = 1, fm = "ml", rotate = "none")
print(afe_viol$loadings, cutoff = 0.3)
cat("Alpha:", round(psych::alpha(itens_viol)$total$raw_alpha, 3), "\n")

cat("\n=== AFE: Clima relacional — Professor ===\n")
itens_clima <- professores |> select(all_of(clima_vars)) |> drop_na()
afe_clima   <- psych::fa(itens_clima, nfactors = 1, fm = "ml", rotate = "none")
print(afe_clima$loadings, cutoff = 0.3)
cat("Alpha:", round(psych::alpha(itens_clima)$total$raw_alpha, 3), "\n")

professores <- professores |>
  mutate(
    idx_violencia_prof = rowMeans(pick(all_of(violencia_vars)), na.rm = TRUE),
    idx_clima_prof     = rowMeans(pick(all_of(clima_vars)),     na.rm = TRUE)
  )

prof_escola <- professores |>
  group_by(escola) |>
  summarise(
    idx_violencia_escola = mean(idx_violencia_prof, na.rm = TRUE),
    idx_clima_escola     = mean(idx_clima_prof,     na.rm = TRUE),
    n_prof_escola        = n(),
    formacao_media_prof  = mean(formacao_prof, na.rm = TRUE),
    .groups = "drop"
  )


# -----------------------------------------------------------------------------
# 5. BANCO MULTINÍVEL — MERGE E PADRONIZAÇÃO
# -----------------------------------------------------------------------------

nivel3 <- escolas |>
  left_join(prof_escola, by = "escola")

# Banco completo SEM drop_na ainda
dados_full <- alunos |>
  left_join(nivel3, by = "escola", suffix = c("", "_esc")) |>
  mutate(
    z_idx_amb_aluno    = as.numeric(scale(idx_amb_aluno)),
    z_idx_f1_prof      = as.numeric(scale(idx_f1_prof)),
    z_idx_f2_segur     = as.numeric(scale(idx_f2_segur)),
    z_inse             = as.numeric(scale(inse)),
    z_inse_escola      = as.numeric(scale(inse_escola)),
    z_idx_viol_escola  = as.numeric(scale(idx_violencia_escola)),
    z_idx_clima_escola = as.numeric(scale(idx_clima_escola)),
    z_form_doc         = as.numeric(scale(form_doc)),
    ln_n_alunos        = log(n_alunos + 1)
  )

# CORREÇÃO: banco HLM com drop_na em TODAS as variáveis usadas nos modelos.
# Isso garante N idêntico em M0...M4, permitindo anova() válido.
# Escolas sem dados de professores são excluídas — documentar como limitação.
vars_modelo <- c(
  "prof_lp", "prof_mt",
  "z_idx_amb_aluno", "z_idx_f1_prof", "z_idx_f2_segur",
  "z_inse", "sexo", "raca_branca", "reprovado", "abandonou",
  "trabalha", "escol_mae", "eng_pais",
  "z_inse_escola", "publica", "rural",
  "z_idx_viol_escola", "z_idx_clima_escola",
  "z_form_doc", "ln_n_alunos",
  "escola", "uf"
)

dados_hlm <- dados_full |>
  drop_na(all_of(vars_modelo))

cat(sprintf("\n=== Banco HLM final ===\n"))
cat(sprintf("Alunos:  %d (%.1f%% do total)\n",
            nrow(dados_hlm),
            nrow(dados_hlm)/nrow(alunos)*100))
cat(sprintf("Escolas: %d\n", n_distinct(dados_hlm$escola)))
cat(sprintf("Excluidos por NA: %d alunos\n",
            nrow(dados_full) - nrow(dados_hlm)))
cat(sprintf("  (principalmente escolas sem dados de professores)\n"))

# Verificar distribuição por UF no banco final
dados_hlm |>
  group_by(uf) |>
  summarise(n_alunos = n(),
            n_escolas = n_distinct(escola),
            .groups = "drop") |>
  print()

# Verificar escala da proficiência
cat(sprintf("\nProficiência LP — média: %.1f | dp: %.1f | min: %.1f | max: %.1f\n",
            mean(dados_hlm$prof_lp, na.rm=TRUE),
            sd(dados_hlm$prof_lp,   na.rm=TRUE),
            min(dados_hlm$prof_lp,  na.rm=TRUE),
            max(dados_hlm$prof_lp,  na.rm=TRUE)))


# -----------------------------------------------------------------------------
# 6. ANÁLISE DESCRITIVA
# -----------------------------------------------------------------------------

# Distribuição das proficiências
alunos |>
  drop_na(prof_lp, prof_mt) |>
  pivot_longer(c(prof_lp, prof_mt),
               names_to = "disciplina", values_to = "prof") |>
  mutate(disciplina = ifelse(disciplina == "prof_lp",
                             "Lingua Portuguesa", "Matematica")) |>
  ggplot(aes(x = prof, fill = disciplina)) +
  geom_histogram(bins = 50, alpha = 0.75, position = "identity") +
  facet_wrap(~uf) +
  scale_fill_manual(values = c("Lingua Portuguesa" = "#185FA5",
                                "Matematica"       = "#0F6E56")) +
  labs(title = "Distribuicao da proficiencia | SAEB 2023 | Regiao Sul | EM",
       x = "Proficiencia (escala SAEB)", y = "Frequencia", fill = NULL) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top")

ggsave("outputs/fig_01_distribuicao_proficiencia.png",
       width = 10, height = 5, dpi = 180)

# Índice de ambiente por quartil vs. proficiência
dados_hlm |>
  mutate(
    faixa_amb = cut(idx_amb_aluno,
                    breaks  = quantile(idx_amb_aluno, probs=c(0,.25,.5,.75,1)),
                    labels  = c("Q1 - mais insalubre","Q2","Q3",
                                "Q4 - mais adequado"),
                    include.lowest = TRUE)
  ) |>
  group_by(faixa_amb) |>
  summarise(
    media_lp = round(mean(prof_lp), 1),
    dp_lp    = round(sd(prof_lp),   1),
    media_mt = round(mean(prof_mt), 1),
    n        = n(),
    .groups  = "drop"
  ) |>
  print()

# Correlação por UF
cat("\n=== Correlacao idx_amb_aluno x proficiencia por UF ===\n")
dados_hlm |>
  group_by(uf) |>
  summarise(
    r_lp = round(cor(idx_amb_aluno, prof_lp), 3),
    r_mt = round(cor(idx_amb_aluno, prof_mt), 3),
    n    = n(),
    .groups = "drop"
  ) |>
  print()


# -----------------------------------------------------------------------------
# 7. MODELOS HLM
# -----------------------------------------------------------------------------
# Todos os modelos usam dados_hlm (N fixo) — anova() válido

# M0: Modelo nulo — ICC
m0_lp <- lmer(prof_lp ~ 1 + (1 | escola), data = dados_hlm, REML = TRUE)
m0_mt <- lmer(prof_mt ~ 1 + (1 | escola), data = dados_hlm, REML = TRUE)

icc_lp <- performance::icc(m0_lp)$ICC_adjusted
icc_mt <- performance::icc(m0_mt)$ICC_adjusted

cat(sprintf("\n=== Modelo Nulo — ICC ===\n"))
cat(sprintf("LP: %.3f (%.1f%% da variancia entre escolas)\n", icc_lp, icc_lp*100))
cat(sprintf("MT: %.3f (%.1f%% da variancia entre escolas)\n", icc_mt, icc_mt*100))

# M1: Apenas controles individuais
m1_lp <- lmer(
  prof_lp ~ z_inse + sexo + raca_branca + reprovado + abandonou +
            trabalha + escol_mae + eng_pais +
            (1 | escola),
  data = dados_hlm, REML = FALSE
)

# M2: + índice geral de percepção do aluno
m2_lp <- lmer(
  prof_lp ~ z_inse + sexo + raca_branca + reprovado + abandonou +
            trabalha + escol_mae + eng_pais +
            z_idx_amb_aluno +
            (1 | escola),
  data = dados_hlm, REML = FALSE
)

# M3: Modelo completo — nível 1 + escola + professor agregado
m3_lp <- lmer(
  prof_lp ~ z_inse + sexo + raca_branca + reprovado + abandonou +
            trabalha + escol_mae + eng_pais +
            z_idx_amb_aluno +
            z_inse_escola + publica + rural +
            z_idx_viol_escola + z_idx_clima_escola +
            z_form_doc + ln_n_alunos +
            (1 | escola),
  data = dados_hlm, REML = FALSE
)

# M4: Slope aleatório — efeito do ambiente varia entre escolas?
m4_lp <- lmer(
  prof_lp ~ z_inse + sexo + raca_branca + reprovado + abandonou +
            trabalha + escol_mae + eng_pais +
            z_idx_amb_aluno +
            z_inse_escola + publica + rural +
            z_idx_viol_escola + z_idx_clima_escola +
            z_form_doc + ln_n_alunos +
            (1 + z_idx_amb_aluno | escola),
  data    = dados_hlm, REML = FALSE,
  control = lmerControl(optimizer = "bobyqa",
                        optCtrl   = list(maxfun = 2e5))
)

# M5 (sensibilidade): sub-índices separados em vez do índice geral
m5_lp <- lmer(
  prof_lp ~ z_inse + sexo + raca_branca + reprovado + abandonou +
            trabalha + escol_mae + eng_pais +
            z_idx_f1_prof + z_idx_f2_segur +   # F1 e F2 separados
            z_inse_escola + publica + rural +
            z_idx_viol_escola + z_idx_clima_escola +
            z_form_doc + ln_n_alunos +
            (1 | escola),
  data = dados_hlm, REML = FALSE
)

# Comparação de modelos (N idêntico — anova() agora válido)
cat("\n=== Comparacao de modelos — LP ===\n")
print(anova(m0_lp, m1_lp, m2_lp, m3_lp, m4_lp))

cat("\n=== M3 vs M5 (sub-indices vs indice geral) ===\n")
print(anova(m3_lp, m5_lp))

# Sumários
cat("\n=== Sumario M3 — LP ===\n"); print(summary(m3_lp))
cat("\n=== Sumario M4 — LP (slope aleatorio) ===\n"); print(summary(m4_lp))

# Repetir para Matemática
m3_mt <- lmer(
  prof_mt ~ z_inse + sexo + raca_branca + reprovado + abandonou +
            trabalha + escol_mae + eng_pais +
            z_idx_amb_aluno +
            z_inse_escola + publica + rural +
            z_idx_viol_escola + z_idx_clima_escola +
            z_form_doc + ln_n_alunos +
            (1 | escola),
  data = dados_hlm, REML = FALSE
)

cat("\n=== Sumario M3 — MT ===\n"); print(summary(m3_mt))


# -----------------------------------------------------------------------------
# 8. DIAGNÓSTICOS E RESULTADOS
# -----------------------------------------------------------------------------

# R² marginal e condicional
cat("\n=== R2 — LP ===\n"); print(performance::r2(m3_lp))
cat("\n=== R2 — MT ===\n"); print(performance::r2(m3_mt))

# Redução de variância vs. modelo nulo
extrair_var <- function(m, grp) {
  v <- as.data.frame(VarCorr(m))
  v[v$grp == grp, "vcov"]
}

cat("\n=== Reducao de variancia vs M0 — LP ===\n")
cat(sprintf("Nivel escola: %.1f%%\n",
    (1 - extrair_var(m3_lp,"escola")   / extrair_var(m0_lp,"escola"))   * 100))
cat(sprintf("Nivel aluno:  %.1f%%\n",
    (1 - extrair_var(m3_lp,"Residual") / extrair_var(m0_lp,"Residual")) * 100))

# Tabela de coeficientes
rotulos <- c(
  "(Intercept)"        = "Intercepto",
  "z_idx_amb_aluno"    = "Percepcao de ambiente (aluno)",
  "z_inse"             = "INSE individual",
  "z_inse_escola"      = "INSE medio da escola",
  "z_idx_viol_escola"  = "Violencia escolar (prof. agregado)",
  "z_idx_clima_escola" = "Clima relacional (prof. agregado)",
  "z_form_doc"         = "Formacao docente adequada (%)",
  "sexo"               = "Feminino",
  "raca_branca"        = "Raca branca",
  "reprovado"          = "Ja foi reprovado",
  "abandonou"          = "Ja abandonou a escola",
  "trabalha"           = "Horas de trabalho fora",
  "escol_mae"          = "Escolaridade da mae",
  "eng_pais"           = "Engajamento dos pais",
  "publica"            = "Escola publica",
  "rural"              = "Escola rural",
  "ln_n_alunos"        = "Porte da escola (log matr.)"
)

tab_lp <- broom.mixed::tidy(m3_lp, effects = "fixed", conf.int = TRUE) |>
  mutate(
    Variavel = dplyr::recode(term, !!!rotulos),
    across(c(estimate, std.error, conf.low, conf.high), ~round(.x, 3)),
    p.value = round(p.value, 4),
    sig = dplyr::case_when(
      p.value < 0.001 ~ "***",
      p.value < 0.01  ~ "**",
      p.value < 0.05  ~ "*",
      TRUE            ~ ""
    )
  ) |>
  select(Variavel, Beta = estimate, EP = std.error,
         IC95_inf = conf.low, IC95_sup = conf.high,
         p = p.value, sig)

cat("\n=== Tabela de coeficientes — M3 LP ===\n")
print(tab_lp, n = 20)

# Gráfico de coeficientes
tab_lp |>
  filter(Variavel != "Intercepto") |>
  mutate(
    destaque = ifelse(grepl("ambiente", Variavel, ignore.case=TRUE),
                      "Variavel principal", "Controles"),
    signif   = ifelse(p < 0.05, "p < 0.05", "n.s.")
  ) |>
  ggplot(aes(x = Beta, y = reorder(Variavel, Beta),
             color = destaque, shape = signif)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray60", linewidth = 0.5) +
  geom_errorbarh(aes(xmin = IC95_inf, xmax = IC95_sup),
                 height = 0.3, linewidth = 0.6) +
  geom_point(size = 3) +
  scale_color_manual(values = c("Variavel principal" = "#185FA5",
                                 "Controles"          = "#888780")) +
  scale_shape_manual(values = c("p < 0.05" = 19, "n.s." = 1)) +
  labs(
    title    = "Modelo HLM — Proficiencia em Lingua Portuguesa",
    subtitle = "Coeficientes padronizados (z-score) | SAEB 2023 | Regiao Sul | EM",
    x        = "Beta (pontos na escala SAEB por 1 DP)",
    y        = NULL,
    color    = NULL,
    shape    = NULL,
    caption  = "IC 95%. Azul: variavel de interesse. Circulo vazio: nao significativo."
  ) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.major.y = element_blank(),
        panel.grid.minor   = element_blank(),
        legend.position    = "top")

ggsave("outputs/fig_02_coeficientes_m3_lp.png",
       width = 10, height = 7, dpi = 180)

# Variância do slope aleatório (M4) — o efeito do ambiente varia entre escolas?
cat("\n=== Variancia do slope aleatorio (M4) ===\n")
print(as.data.frame(VarCorr(m4_lp)))

cat("\n=== Analise concluida. Figuras em outputs/ ===\n")