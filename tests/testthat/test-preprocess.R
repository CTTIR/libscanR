test_that("ls_baseline produces shifted intensities", {
  s <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1, n_channels = 128)
  s2 <- ls_baseline(s, method = "snip", iterations = 30)
  expect_s3_class(s2, "libs_spectrum")
  expect_false(is.null(s2$baseline))
  expect_equal(length(s2$baseline), s2$n_channels)
})

test_that("ls_baseline supports multiple methods", {
  s <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1, n_channels = 64)
  for (m in c("snip", "als", "rolling_ball", "linear", "polynomial")) {
    s2 <- ls_baseline(s, method = m, iterations = 20, order = 2)
    expect_s3_class(s2, "libs_spectrum")
  }
})

test_that("ls_normalize gives expected sums / scales", {
  s <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 2, n_channels = 128)
  tot <- ls_normalize(s, method = "total")
  expect_equal(sum(tot$intensity[1, ]), 1, tolerance = 1e-8)

  mx <- ls_normalize(s, method = "max")
  expect_equal(max(mx$intensity[1, ]), 1, tolerance = 1e-8)
})

test_that("ls_smooth reduces variance", {
  s <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1, n_channels = 128, noise_level = 0.1)
  s2 <- ls_smooth(s, method = "moving_avg", window = 9)
  expect_s3_class(s2, "libs_spectrum")
  expect_lt(stats::sd(diff(s2$intensity[1, ])),
            stats::sd(diff(s$intensity[1, ])))
})

test_that("ls_crop restricts wavelength range", {
  s <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1, n_channels = 256)
  s2 <- ls_crop(s, min_nm = 400, max_nm = 500)
  expect_true(min(s2$wavelength) >= 400)
  expect_true(max(s2$wavelength) <= 500)
})

test_that("ls_average_shots collapses to single shot", {
  s <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1, n_channels = 64, n_shots = 8)
  a <- ls_average_shots(s, remove_outliers = TRUE)
  expect_equal(a$n_shots, 1)
})

test_that("ls_crop works on dataset", {
  ds <- ls_example_data("tissue", n_channels = 64)
  ds2 <- ls_crop(ds, 300, 500)
  expect_s3_class(ds2, "libs_dataset")
  expect_lt(ds2$n_channels, ds$n_channels)
})

test_that("ls_baseline works on a dataset", {
  ds <- ls_example_data("tissue", n_channels = 64)[1:3]
  ds2 <- ls_baseline(ds, method = "linear")
  expect_s3_class(ds2, "libs_dataset")
})
