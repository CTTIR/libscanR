# Tests for R/io-read.R and R/io-write.R uncovered branches -------------------

test_that("ls_read_spectrum reads TSV and TXT formats", {
  tsv <- withr::local_tempfile(fileext = ".tsv")
  write.table(data.frame(wavelength = seq(200, 300, length.out = 10),
                         intensity = 1:10),
              tsv, sep = "\t", row.names = FALSE)
  s_tsv <- ls_read_spectrum(tsv, verbose = FALSE)
  expect_equal(s_tsv$n_channels, 10)

  txt <- withr::local_tempfile(fileext = ".txt")
  write.table(data.frame(wavelength = seq(200, 300, length.out = 10),
                         intensity = 1:10),
              txt, sep = " ", row.names = FALSE)
  s_txt <- ls_read_spectrum(txt, verbose = FALSE)
  expect_equal(s_txt$n_channels, 10)
})

test_that("ls_read_spectrum auto-detects unknown extension as csv", {
  tmp <- withr::local_tempfile(fileext = ".dat")
  utils::write.csv(data.frame(wavelength = seq(200, 300, length.out = 10),
                              intensity = 1:10), tmp, row.names = FALSE)
  s <- ls_read_spectrum(tmp, format = "auto", verbose = FALSE)
  expect_s3_class(s, "libs_spectrum")
})

test_that("ls_read_spectrum verbose emits message and merges user metadata", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  utils::write.csv(data.frame(wavelength = seq(200, 300, length.out = 10),
                              intensity = 1:10), tmp, row.names = FALSE)
  expect_message(ls_read_spectrum(tmp, verbose = TRUE), "channels")
  s <- ls_read_spectrum(tmp, metadata = list(operator = "RH"), verbose = FALSE)
  expect_equal(s$metadata$operator, "RH")
})

test_that("ls_read_spectrum supports multiple intensity columns -> matrix", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  utils::write.csv(data.frame(wl = seq(200, 300, length.out = 10),
                              s1 = 1:10, s2 = 11:20, s3 = 21:30),
                   tmp, row.names = FALSE)
  s <- ls_read_spectrum(tmp, verbose = FALSE)
  expect_equal(s$n_shots, 3)
})

test_that("ls_read_csv delegates to ls_read_spectrum", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  utils::write.csv(data.frame(wavelength = seq(200, 300, length.out = 10),
                              intensity = 1:10), tmp, row.names = FALSE)
  s <- ls_read_csv(tmp, verbose = FALSE)
  expect_s3_class(s, "libs_spectrum")
})

test_that("ls_read_dir errors on missing dir and empty pattern", {
  expect_error(ls_read_dir("/no/such/dir", verbose = FALSE), "not found")
  empty <- withr::local_tempdir()
  expect_error(ls_read_dir(empty, verbose = FALSE), "No files matching")
})

test_that(".pick_col validates names, indices, and types", {
  df <- data.frame(a = 1:3, b = 4:6)
  expect_equal(.pick_col(df, "a"), 1:3)
  expect_equal(.pick_col(df, 2), 4:6)
  expect_error(.pick_col(df, "z"), "not found")
  expect_error(.pick_col(df, 5), "out of range")
  expect_error(.pick_col(df, TRUE), "must be character or numeric")
})

test_that(".pick_cols validates names, expands default, and ranges", {
  df <- data.frame(a = 1:3, b = 4:6, c = 7:9)
  expect_equal(ncol(.pick_cols(df, c("b", "c"))), 2)
  # default intensity_col == 2 with >2 cols expands to remaining columns
  expect_equal(ncol(.pick_cols(df, 2)), 2)
  expect_error(.pick_cols(df, c("x", "y")), "not found")
  expect_error(.pick_cols(df, c(1, 99)), "out of range")
  expect_error(.pick_cols(df, list(1)), "must be character or numeric")
})

test_that("ls_write_csv writes single-shot, multi-shot and metadata", {
  s1 <- ls_simulate_spectrum(seed = 1, n_channels = 20, n_shots = 1)
  p1 <- withr::local_tempfile(fileext = ".csv")
  ls_write_csv(s1, p1, include_metadata = TRUE)
  txt <- readLines(p1)
  expect_true(any(grepl("^#", txt)))   # metadata comment lines present
  expect_true(any(grepl("intensity", txt)))

  s2 <- ls_simulate_spectrum(seed = 2, n_channels = 20, n_shots = 3)
  p2 <- withr::local_tempfile(fileext = ".csv")
  ls_write_csv(s2, p2, include_metadata = FALSE)
  hdr <- readLines(p2, n = 1)
  expect_true(grepl("shot_1", hdr))
})

test_that("ls_export_spectra writes spectra and sample_info, respects overwrite", {
  ds <- ls_example_data("calibration", n_channels = 64)
  ds <- ls_dataset(ds$spectra[1:3], sample_info = ds$sample_info[1:3, ])
  outdir <- file.path(withr::local_tempdir(), "export")
  ls_export_spectra(ds, outdir)
  expect_true(file.exists(file.path(outdir, "sample_info.csv")))
  csvs <- list.files(outdir, pattern = "\\.csv$")
  expect_true(length(csvs) >= 4)  # 3 spectra + sample_info

  # second call without overwrite should warn (files exist)
  expect_warning(ls_export_spectra(ds, outdir, overwrite = FALSE), "skipping")
})
