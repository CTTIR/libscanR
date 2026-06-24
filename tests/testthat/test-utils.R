# Tests for R/utils.R internal helpers ----------------------------------------

test_that(".validate_spectrum / .validate_dataset accept and reject", {
  s <- ls_simulate_spectrum(seed = 1, n_channels = 20, n_shots = 2)
  expect_true(.validate_spectrum(s))
  expect_error(.validate_spectrum(list()), "libs_spectrum")
  ds <- ls_example_data("calibration", n_channels = 32)
  expect_true(.validate_dataset(ds))
  expect_error(.validate_dataset(list()), "libs_dataset")
})

test_that(".wavelength_to_idx finds nearest channel", {
  wl <- seq(200, 300, by = 1)
  expect_equal(.wavelength_to_idx(wl, 250.2), which.min(abs(wl - 250.2)))
})

test_that(".mean_intensity handles vector, single-row, and multi-row", {
  s_vec <- ls_simulate_spectrum(seed = 1, n_channels = 10, n_shots = 1)
  s_vec$intensity <- as.numeric(s_vec$intensity)
  expect_type(.mean_intensity(s_vec), "double")

  s1 <- ls_simulate_spectrum(seed = 2, n_channels = 10, n_shots = 1)
  expect_length(.mean_intensity(s1), 10)

  s3 <- ls_simulate_spectrum(seed = 3, n_channels = 10, n_shots = 3)
  expect_length(.mean_intensity(s3), 10)
})

test_that(".build_intensity_matrix sets rownames from sample_id", {
  ds <- ls_example_data("calibration", n_channels = 32)
  m <- .build_intensity_matrix(ds$spectra[1:3])
  expect_true(is.matrix(m))
  expect_equal(nrow(m), 3)
})

test_that(".trapz integrates and degenerates correctly", {
  expect_equal(.trapz(c(1), c(5)), 0)
  expect_equal(.trapz(c(0, 1), c(0, 2)), 1)
})

test_that(".estimate_noise handles short and long vectors", {
  expect_equal(.estimate_noise(c(1, 2, 3)), stats::sd(c(1, 2, 3)))
  long <- rnorm(100)
  expect_type(.estimate_noise(long), "double")
})

test_that(".ensure_sorted reorders vector and matrix intensities", {
  wl <- c(3, 1, 2)
  res_v <- .ensure_sorted(wl, c(30, 10, 20))
  expect_equal(res_v$wavelength, c(1, 2, 3))
  expect_equal(res_v$intensity, c(10, 20, 30))

  m <- matrix(c(30, 10, 20, 60, 40, 50), nrow = 2, byrow = TRUE)
  res_m <- .ensure_sorted(wl, m)
  expect_equal(res_m$intensity[1, ], c(10, 20, 30))

  # already sorted: unchanged
  res_s <- .ensure_sorted(c(1, 2, 3), c(1, 2, 3))
  expect_equal(res_s$wavelength, c(1, 2, 3))
})

test_that(".require_pkg passes for present, aborts for missing", {
  expect_true(.require_pkg("stats"))
  expect_error(.require_pkg("definitely.not.a.pkg.xyz", "some reason"),
               "is required")
})

test_that(".range_str and .meta_get format correctly", {
  expect_equal(.range_str(c(1.234, 5.678), digits = 1), "1.2-5.7")
  expect_equal(.meta_get(NULL, "a", default = "d"), "d")
  expect_equal(.meta_get(list(a = 1), "b", default = "d"), "d")
  expect_equal(.meta_get(list(a = 1), "a"), 1)
})

test_that(".extdata_path returns a character path", {
  expect_type(.extdata_path("foo.csv"), "character")
})
