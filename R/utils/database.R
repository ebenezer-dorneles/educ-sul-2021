save_table <- function(con, df, nome_tabela, chave = NULL) {
  message(paste0("\n", glue::glue("🛠️ Saving table {nome_tabela}..."), "\n"))

  # Overwrite the table if it alredy exists (idempotent — safe to re-run)
  if (DBI::dbExistsTable(con, nome_tabela)) {
    DBI::dbRemoveTable(con, nome_tabela)
  }

  DBI::dbWriteTable(con, nome_tabela, as.data.frame(df), row.names = FALSE)

  total_rows <- DBI::dbGetQuery(con, glue::glue("SELECT COUNT(*) AS n FROM {nome_tabela}"))$n
  message(paste0("\n", glue::glue("✅ {nome_tabela}: {total_rows} rows saved"), "\n"))

  # Create index on the primary key if provided
  if (!is.null(chave)) {
    DBI::dbExecute(con, glue::glue(
      "CREATE INDEX IF NOT EXISTS idx_{nome_tabela}_{chave}
       ON {nome_tabela} ({chave})"
    ))
  }
}
