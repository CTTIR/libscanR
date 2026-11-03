test_that("SNIP clipping is independent of traversal direction", {
  y <- c(3, 4, 9, 30, 8, 6, 5, 9, 20, 10, 4, 3)
  expect_equal(.baseline_snip(y, 4), rev(.baseline_snip(rev(y), 4)), tolerance = 1e-12)
})

test_that("local Savitzky-Golay preserves constants and polynomials including edges", {
  x <- -10:10
  expect_equal(.savgol_local(rep(15, 21), 7, 3), rep(15, 21), tolerance = 1e-10)
  y <- 5 + 2 * x - x^2 + 0.03 * x^3
  expect_equal(.savgol_local(y, 7, 3), y, tolerance = 1e-10)
  if (requireNamespace("signal", quietly = TRUE)) {
    set.seed(42)
    noisy <- y + rnorm(21)
    expect_equal(.savgol_local(noisy, 7, 3),
                 as.numeric(signal::sgolayfilt(noisy, p = 3, n = 7)), tolerance = 1e-9)
  }
})

test_that("sparse ALS agrees with an independent dense normal-equation solve", {
  y <- c(3, 4, 7, 20, 7, 5, 6, 20, 6, 5)
  D <- diff(diag(length(y)), differences = 2)
  weights <- rep(1, length(y))
  for (i in 1:15) {
    dense <- as.numeric(solve(diag(weights) + 100 * crossprod(D), weights * y))
    weights <- ifelse(y > dense, 0.1, 0.9)
  }
  expect_equal(.baseline_als(y, lambda = 100, p = 0.1, n_iter = 15), dense,
               tolerance = 1e-10)
})

test_that("normalization rejects zero divisors and retains baseline provenance", {
  zero <- ls_spectrum(500:504, rep(0, 5))
  expect_error(ls_normalize(zero), "denominator is zero")
  expect_equal(ls_normalize(zero, "snv")$intensity, matrix(0, 1, 5))
  corrected <- ls_baseline(ls_spectrum(500:504, c(1, 3, 8, 3, 1)), "linear")
  normalized <- ls_normalize(corrected, "max")
  expect_null(normalized$baseline)
  expect_equal(normalized$metadata$baseline_history[[1]]$values, corrected$baseline)
  expect_equal(vapply(normalized$metadata$processing, `[[`, "", "operation"),
               c("baseline", "normalize"))
  expect_equal(ls_average_shots(ls_spectrum(500:504, matrix(4, 5, 5)),
                                remove_outliers = TRUE)$intensity, matrix(4, 1, 5))
})

test_that("invalid preprocessing parameters fail clearly", {
  s <- ls_spectrum(500:510, 1:11)
  expect_error(ls_baseline(s, iterations = NA), "iterations")
  expect_error(ls_baseline(s, p = 1), "p")
  expect_error(ls_smooth(s, window = 12), "exceeds")
  expect_error(ls_smooth(s, window = 5, poly_order = 5), "poly_order")
  expect_error(ls_smooth(ls_spectrum(c(500, 501, 503, 504, 505), 1:5), window = 5), "evenly spaced")
  expect_error(ls_crop(s, 505, 501), "max_nm")
  expect_error(ls_average_shots(s, trim = 0.9), "trim")
})

test_that("two-channel peak detection and out-of-range lines are explicit", {
  expect_equal(nrow(ls_find_peaks(ls_spectrum(c(500, 501), c(1, 2)))), 0L)
  s <- ls_spectrum(500:510, c(0, 0, 1, 2, 5, 10, 5, 2, 1, 0, 0))
  expect_error(ls_peak_area(s, 393), "center_nm")
  expect_error(ls_peak_area(s, 505, window_nm = 0), "window_nm")
  y <- c(0, 1, 5, 1, 0)
  expect_equal(.peak_fwhm(1:5, y, 3), .peak_fwhm(1:5, y + 100, 3))
})

test_that("duplicate map positions cannot overwrite a different sample", {
  specs <- lapply(1:4, function(i) ls_spectrum(500:510, 1:11, list(sample_id = paste0("s", i))))
  ds <- ls_dataset(specs, data.frame(sample_id = paste0("s", 1:4),
                                     x_pos = c(0, 1, 0, 0), y_pos = c(0, 0, 1, 1)))
  expect_error(ls_build_map(ds, "test", 505), "coordinate pairs must be unique")
  ds$sample_info$x_pos[1] <- NA
  expect_error(ls_build_map(ds, "test", 505), "finite numeric")
})

test_that("normalized peak annotations use the same scale as their spectrum", {
  s <- ls_spectrum(500:510, c(0, 0, 0, 1, 2, 50, 2, 1, 0, 0, 0))
  p <- ls_plot_spectrum(s, show_peaks = TRUE, normalize = TRUE, snr_threshold = 0)
  built <- ggplot2::ggplot_build(p)
  expect_equal(max(built$data[[1]]$y), 1)
  expect_equal(max(built$data[[2]]$y), 1)
})

test_that("seeded example generation is reproducible without changing session RNG", {
  withr::local_seed(123)
  before <- .Random.seed
  first <- ls_example_data("tissue", seed = 8, n_channels = 16)
  expect_identical(.Random.seed, before)
  runif(10)
  second <- ls_example_data("tissue", seed = 8, n_channels = 16)
  expect_equal(first$intensity_matrix, second$intensity_matrix)
  rm(".Random.seed", envir = .GlobalEnv)
  ls_simulate_spectrum(seed = 2, n_channels = 16)
  expect_false(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
  ls_example_data("tissue", seed = 2, n_channels = 16)
  expect_false(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
})
