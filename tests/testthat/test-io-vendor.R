# Tests for R/io-vendor.R -----------------------------------------------------

test_that("ls_read_sciaps parses header metadata and data table", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    "# SciAps Z-903",
    "# Serial: 12345",
    "# Gate Delay (us): 2.5",
    "# Integration (us): 1000",
    "# Model: Z-903",
    "wavelength,intensity",
    "200.0,50",
    "200.5,55",
    "201.0,52"
  ), tmp)
  spec <- ls_read_sciaps(tmp, verbose = FALSE)
  expect_s3_class(spec, "libs_spectrum")
  expect_equal(spec$n_channels, 3)
  expect_equal(spec$metadata$vendor, "SciAps")
  expect_equal(spec$metadata$serial_number, "12345")
  expect_equal(spec$metadata$gate_delay_us, 2.5)
  expect_equal(spec$metadata$integration_time_us, 1000)
})

test_that("ls_read_sciaps handles multiple intensity columns (matrix)", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    "# SciAps Z-903",
    "wavelength,shot1,shot2",
    "200.0,50,52",
    "200.5,55,58",
    "201.0,52,50"
  ), tmp)
  spec <- ls_read_sciaps(tmp, verbose = FALSE)
  expect_equal(spec$n_shots, 2)
})

test_that("ls_read_sciaps emits message when verbose", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c("wavelength,intensity", "200.0,50", "200.5,55", "201.0,52"), tmp)
  expect_message(ls_read_sciaps(tmp, verbose = TRUE), "SciAps")
})

test_that("ls_read_sciaps aborts on missing file", {
  expect_error(ls_read_sciaps("/no/such/file.csv", verbose = FALSE),
               "not found")
})

test_that("ls_read_aurora parses model and data", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    "Applied Spectra J200",
    "Model,J200",
    "wl,shot1,shot2",
    "200.0,50,52",
    "200.5,55,58",
    "201.0,52,50"
  ), tmp)
  spec <- ls_read_aurora(tmp, verbose = FALSE)
  expect_s3_class(spec, "libs_spectrum")
  expect_equal(spec$metadata$vendor, "Applied Spectra")
  expect_equal(spec$metadata$instrument_model, "J200")
  expect_equal(spec$n_shots, 2)
})

test_that("ls_read_aurora single intensity column yields vector path", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c("wl,intensity", "200.0,50", "200.5,55", "201.0,52"), tmp)
  spec <- ls_read_aurora(tmp, verbose = FALSE)
  expect_equal(spec$n_shots, 1)
})

test_that("ls_read_aurora emits message when verbose and aborts on missing", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c("wl,intensity", "200.0,50", "200.5,55", "201.0,52"), tmp)
  expect_message(ls_read_aurora(tmp, verbose = TRUE), "Applied Spectra")
  expect_error(ls_read_aurora("/no/such/file.csv", verbose = FALSE), "not found")
})

test_that("ls_read_auto dispatches to SciAps reader", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    "# SciAps Z-903",
    "wavelength,intensity",
    "200.0,50",
    "200.5,55",
    "201.0,52"
  ), tmp)
  spec <- ls_read_auto(tmp, verbose = FALSE)
  expect_equal(spec$metadata$vendor, "SciAps")
})

test_that("ls_read_auto dispatches to Aurora reader", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    "Applied Spectra J200",
    "wl,intensity",
    "200.0,50",
    "200.5,55",
    "201.0,52"
  ), tmp)
  spec <- ls_read_auto(tmp, verbose = FALSE)
  expect_equal(spec$metadata$vendor, "Applied Spectra")
})

test_that("ls_read_auto dispatches to directory reader", {
  tmp <- withr::local_tempdir()
  for (i in 1:2) {
    utils::write.csv(data.frame(w = seq(200, 300, length.out = 10), i = 1:10),
                     file.path(tmp, paste0("s", i, ".csv")), row.names = FALSE)
  }
  out <- ls_read_auto(tmp, verbose = FALSE)
  expect_s3_class(out, "libs_dataset")
})

test_that("ls_read_auto falls back to generic reader and aborts on missing", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  utils::write.csv(data.frame(w = 1:10, i = 1:10), tmp, row.names = FALSE)
  spec <- ls_read_auto(tmp, verbose = FALSE)
  expect_s3_class(spec, "libs_spectrum")
  expect_error(ls_read_auto("/no/such/path.csv", verbose = FALSE), "not found")
})

test_that(".detect_data_start finds the wavelength header and numeric fallback", {
  expect_equal(.detect_data_start(c("# meta", "wavelength,i", "1,2")), 2L)
  expect_equal(.detect_data_start(c("# meta", "", "1.0,2.0")), 3L)
  expect_equal(.detect_data_start(c("# only comments")), 1L)
})

test_that(".parse_sciaps_header extracts known fields", {
  meta <- .parse_sciaps_header(c("# Serial: ABC", "# Gate Delay (us): 3.1",
                                 "# Integration (us): 500", "# Model: Z1"))
  expect_equal(meta$serial_number, "ABC")
  expect_equal(meta$gate_delay_us, 3.1)
  expect_equal(meta$integration_time_us, 500)
  expect_equal(meta$instrument_model, "Z1")
})
