.calibration_fixture <- function(response = c(2, 4, 5, 8, 11), gain = 1) {
  ls_dataset(lapply(seq_along(response), function(i) {
    ls_spectrum(c(499, 500, 501), c(0, gain * response[i], 0),
                list(sample_id = paste0("standard_", i)))
  }))
}

test_that("response-scale limits have concentration units and are gain invariant", {
  ds <- .calibration_fixture()
  original <- ds
  cal <- ls_calibrate(ds, "Ca", 500, 1:5, window_nm = 2, verbose = FALSE)
  gained <- ls_calibrate(.calibration_fixture(gain = 10), "Ca", 500, 1:5,
                         window_nm = 2, verbose = FALSE)
  # Independent hand-computed response fit: slope2.2, intercept-.6, SSE1.6.
  expected <- 3 * sqrt(1.6 / 3) / 2.2
  expect_equal(cal$lod, expected, tolerance = 1e-12)
  expect_equal(cal$loq, 10 * sqrt(1.6 / 3) / 2.2, tolerance = 1e-12)
  expect_equal(gained$lod, expected, tolerance = 1e-12)
  expect_equal(ls_lod(cal), expected, tolerance = 1e-12)
  expect_equal(predict(cal, cal$intensities), predict(gained, gained$intensities))
  expect_identical(ds, original)
})

test_that("internal-standard prediction reuses ratios and the fitted window", {
  ds <- ls_dataset(lapply(1:5, function(i) {
    ls_spectrum(c(499, 500, 501, 599, 600, 601),
                c(0, i * (i + 1), 0, 0, i + 1, 0),
                list(sample_id = paste0("standard_", i)))
  }))
  cal <- ls_calibrate(ds, "Ca", 500, 5 * (1:5), method = "internal_std",
                      internal_std_nm = 600, window_nm = 2, verbose = FALSE)
  unknown <- ls_spectrum(ds$wavelength, c(0, 21, 0, 0, 3, 0))
  expect_equal(ls_quantify(cal, unknown)$concentration, 35, tolerance = 1e-12)
  expect_equal(ls_quantify(cal, ds)$concentration, 5 * (1:5), tolerance = 1e-12)
  expect_error(ls_quantify(cal, ds, window_nm = 1), "fitted integration window")
  zero <- ls_spectrum(ds$wavelength, c(0, 21, 0, 0, 0, 0))
  expect_error(ls_quantify(cal, zero), "Internal-standard.*positive")
  saved <- tempfile(fileext = ".rds")
  on.exit(unlink(saved), add = TRUE)
  saveRDS(cal, saved)
  expect_equal(ls_quantify(readRDS(saved), unknown)$concentration, 35, tolerance = 1e-12)
})

test_that("PLS quantification uses every fitted channel for new spectra", {
  skip_if_not_installed("pls")
  x1 <- c(1, 2, 4, 3, 6, 5, 2, 7)
  x2 <- c(7, 3, 4, 8, 1, 6, 2, 5)
  make <- function(a, b) ls_dataset(lapply(seq_along(a), function(i) {
    ls_spectrum(c(499, 500, 501, 600), c(a[i], b[i], a[i] - b[i], 100),
                list(sample_id = paste0("p", i)))
  }))
  ds <- make(x1, x2)
  cal <- ls_calibrate(ds, "Ca", 500, 1 + 2 * x1 + 3 * x2, method = "pls",
                      pls_window_nm = c(499, 501), n_components = 2, verbose = FALSE)
  unknown <- make(c(9, 3), c(2, 11))
  out <- ls_quantify(cal, unknown)
  expect_equal(out$concentration, c(25, 40), tolerance = 1e-10)
  expect_equal(ls_quantify(cal, unknown$spectra[[1]])$concentration, 25, tolerance = 1e-10)
  expect_true(is.na(cal$lod))
  expect_true(is.na(ls_lod(cal)))
  expect_true(all(is.na(out$below_lod)))
  expect_lt(cal$training_rmse, 1e-10)
  expect_error(predict(cal, matrix(1, 2, 1)), "fitted feature columns")
})

test_that("spectral prediction rejects changed axes, processing and legacy recipes", {
  ds <- .calibration_fixture()
  cal <- ls_calibrate(ds, "Ca", 500, 1:5, window_nm = 2, verbose = FALSE)
  shifted <- ls_spectrum(ds$wavelength + 0.01, c(0, 3, 0))
  expect_error(ls_quantify(cal, shifted), "feature contract")
  processed <- ls_spectrum(ds$wavelength, c(0, 3, 0),
    list(processing = list(list(operation = "normalize", parameters = list(method = "max")))))
  expect_error(ls_quantify(cal, processed), "feature contract")
  legacy <- cal
  legacy$feature_contract <- NULL
  expect_error(ls_quantify(legacy, ds), "refit")
  expect_length(predict(legacy, c(2, 4)), 2L)
  malformed <- ls_spectrum(ds$wavelength, c(0, 3, 0), list(processing = "normalized"))
  expect_error(ls_quantify(cal, malformed), "ordered list")
})

test_that("blank limits use replicated integrated responses, not channel variability", {
  ds <- .calibration_fixture()
  cal <- ls_calibrate(ds, "Ca", 500, 1:5, window_nm = 2, verbose = FALSE)
  blank <- ls_spectrum(ds$wavelength, rbind(c(0, 2, 0), c(0, 4, 0), c(0, 6, 0)))
  expect_equal(ls_lod(cal, blank), 6 / 2.2, tolerance = 1e-12)
  expect_equal(ls_loq(cal, blank), 20 / 2.2, tolerance = 1e-12)
  expect_error(ls_lod(cal, ls_spectrum(ds$wavelength, c(0, 2, 0))), "replicate shots")
})

test_that("manual inverse prediction uses supplied features rather than formula globals", {
  response <- 1:3
  concentration <- c(3, 5, 7)
  model <- stats::lm(concentration ~ response)
  cal <- ls_calibration("Ca", 500, concentration, response, model)
  expect_equal(predict(cal, c(4, 5)), c(9, 11))
  expect_error(predict(cal, c(4, NA_real_)), "finite numeric")
  expect_error(ls_calibrate(.calibration_fixture(), "Ca", 500, rep(1, 5)), "distinct concentrations")
  expect_error(ls_calibrate(.calibration_fixture(), "Ca", 500, c(1:4, Inf)), "finite numeric")
})

test_that("saved calibration predicts identically after processed CSV roundtrip", {
  ds <- ls_dataset(lapply(1:5, function(i) {
    ls_spectrum(499:503, c(0, i, 0, 10, 0), list(sample_id = paste0("csv_", i)))
  }))
  ds <- ls_crop(ls_normalize(ds, "total"), 499, 501)
  cal <- ls_calibrate(ds, "Ca", 500, 1:5, verbose = FALSE)
  path <- tempfile(fileext = ".csv")
  saved <- tempfile(fileext = ".rds")
  on.exit(unlink(c(path, saved)), add = TRUE)
  saveRDS(cal, saved)
  ls_write_csv(ds$spectra[[3]], path)
  restored <- ls_read_csv(path, verbose = FALSE)
  expect_equal(ls_quantify(readRDS(saved), restored)$concentration,
               ls_quantify(cal, ds$spectra[[3]])$concentration, tolerance = 1e-12)
  expect_identical(names(restored$metadata$processing[[1]]$parameters),
                   names(ds$spectra[[3]]$metadata$processing[[1]]$parameters))
})

test_that("manual nonlinear or offset formulas cannot masquerade as linear responses", {
  response <- 1:5
  concentration <- 2 + log(response)
  transformed <- ls_calibration("Ca", 500, concentration, response,
                                 stats::lm(concentration ~ log(response)))
  expect_error(predict(transformed, c(6, 7)), "plain numeric predictor")
  shifted <- ls_calibration("Ca", 500, concentration, response,
                             stats::lm(concentration ~ response + offset(rep(1, 5))))
  expect_error(predict(shifted, c(6, 7)), "offsets")
})

test_that("generalized linear model links cannot be treated as concentrations", {
  response <- 1:5
  concentration <- 2^(response - 1)
  model <- stats::glm(concentration ~ response, family = stats::poisson())
  cal <- ls_calibration("Ca", 500, concentration, response, model)
  expect_error(predict(cal, c(6, 7)), "generalized linear model")
})
