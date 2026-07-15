source("../../R/utils/unzip.R")

test_that("errors if zip path is missing", {
  expect_error(
    unzip_microdata(),
    "Please provide the path to the ZIP file."
  )
})

test_that("errors if zip file does not exist", {
  expect_error(
    unzip_microdata("data/censo_2021.zip", "data/censo_2021"),
    "The ZIP file does not exist."
  )
})

test_that("errors if output directory is missing", {
  tmp <- tempfile(fileext = ".zip")
  file.create(tmp)

  expect_error(
    unzip_microdata(tmp),
    "Please provide the path to the output directory."
  )
})

test_that("unzips file correctly", {
  tmp_zip <- tempfile(fileext = ".zip")
  tmp_dir <- tempdir()
  tmp_file <- tempfile(tmpdir = tmp_dir)

  writeLines("conteudo", tmp_file)
  zip::zip(tmp_zip, tmp_file)

  output_dir <- tempfile()
  dir.create(output_dir)

  result <- unzip_microdata(tmp_zip, output_dir)

  expect_true(dir.exists(output_dir))
  expect_equal(result, output_dir)
})
