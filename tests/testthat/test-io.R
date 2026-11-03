test_that("ls_read_spectrum reads CSV", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  wl <- seq(200, 300, length.out = 50)
  int <- exp(-((wl - 250)^2) / 10)
  utils::write.csv(data.frame(wavelength = wl, intensity = int),
                   tmp, row.names = FALSE)
  s <- ls_read_spectrum(tmp, verbose = FALSE)
  expect_s3_class(s, "libs_spectrum")
  expect_equal(s$n_channels, 50)
})

test_that("ls_read_dir imports multiple spectra", {
  tmp <- withr::local_tempdir()
  for (i in 1:3) {
    wl <- seq(200, 300, length.out = 30)
    int <- exp(-((wl - 250)^2) / 10) + stats::rnorm(30, 0, 0.01)
    utils::write.csv(data.frame(w = wl, i = int),
                     file.path(tmp, paste0("s", i, ".csv")),
                     row.names = FALSE)
  }
  ds <- ls_read_dir(tmp, verbose = FALSE)
  expect_s3_class(ds, "libs_dataset")
  expect_equal(ds$n_spectra, 3)
})

test_that("ls_read_spectrum fails on missing file", {
  expect_error(ls_read_spectrum("/nope/does-not-exist.csv", verbose = FALSE),
               "not found")
})

test_that("ls_write_csv round-trip", {
  s <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1, n_channels = 50, n_shots = 1)
  tmp <- withr::local_tempfile(fileext = ".csv")
  ls_write_csv(s, tmp, include_metadata = FALSE)
  s2 <- ls_read_spectrum(tmp, verbose = FALSE)
  expect_equal(s2$n_channels, 50)
})

test_that("ls_read_auto dispatches correctly", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  utils::write.csv(data.frame(w = 1:10, i = 1:10), tmp,
                   row.names = FALSE)
  s <- ls_read_auto(tmp, verbose = FALSE)
  expect_s3_class(s, "libs_spectrum")
})
