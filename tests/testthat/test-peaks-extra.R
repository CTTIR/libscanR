# Additional tests for R/peaks.R ----------------------------------------------

test_that("ls_find_peaks returns empty tibble when no peaks pass threshold", {
  s <- ls_simulate_spectrum(elements = c(Ca = 1), seed = 1, n_channels = 64,
                            noise_level = 0)
  # absurdly high threshold -> no peaks
  pk <- ls_find_peaks(s, snr_threshold = 1e9, min_prominence = 1)
  expect_s3_class(pk, "tbl_df")
  expect_equal(nrow(pk), 0)
  expect_true(all(c("wavelength_nm", "intensity", "snr", "prominence",
                    "fwhm_nm", "area") %in% names(pk)))
})

test_that("ls_peak_area gaussian_fit method runs", {
  s <- ls_simulate_spectrum(elements = c(Ca = 10000), seed = 1,
                            n_channels = 1024)
  s <- ls_baseline(s, method = "snip", iterations = 30)
  area <- ls_peak_area(s, 393.37, window_nm = 2, method = "gaussian_fit")
  expect_gte(area, 0)
})

test_that("ls_identify_peaks validates input and missing columns", {
  expect_error(ls_identify_peaks(42), "data.frame")
  bad <- tibble::tibble(foo = 1)
  expect_error(ls_identify_peaks(bad), "missing columns")
})

test_that("ls_identify_peaks warns when no DB lines match the filter", {
  s <- ls_simulate_spectrum(elements = c(Ca = 10000), seed = 1,
                            n_channels = 512)
  pk <- ls_find_peaks(s, snr_threshold = 2)
  expect_warning(
    out <- ls_identify_peaks(pk, elements = "Zz", tolerance_nm = 0.2),
    "No lines match"
  )
  expect_true("element" %in% names(out))
})

test_that(".peak_prominence and .peak_fwhm produce numeric results", {
  y <- c(0, 1, 5, 1, 0)
  expect_type(.peak_prominence(y, 3), "double")
  wl <- c(1, 2, 3, 4, 5)
  expect_type(.peak_fwhm(wl, y, 3), "double")
})
