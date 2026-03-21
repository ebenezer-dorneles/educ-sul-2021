library(stringr)

#' Filter columns by expression
#' @param data data.frame
#' @param expression expression to filter columns
#' @return vector of column names
filter_by_col <- function (data, expression) {
  filter_by_col <- colnames(data) %>%
    str_detect(expression) %>%
    which() %>%
    colnames(data)[.]

  return(filter_by_col)
}