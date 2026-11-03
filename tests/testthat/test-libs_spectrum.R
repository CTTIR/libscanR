test_that("ls_spectrum constructs a valid libs_spectrum", {
  wl <- seq(200, 900, length.out = 100)
  int <- exp(-((wl - 400)^2) / 50)
  s <- ls_spectrum(wl, int, metadata = list(sample_id = "t1"))
  expect_s3_class(s, "libs_spectrum")
  expect_true(is_libs_spectrum(s))
  expect_equal(s$n_channels, 100)
  expect_equal(s$n_shots, 1)
  expect_equal(s$range_nm, c(200, 900))
})

test_that("ls_spectrum accepts multi-shot matrix", {
  wl <- seq(200, 900, length.out = 50)
  int <- matrix(stats::rnorm(5 * 50), nrow = 5)
  s <- ls_spectrum(wl, int)
  expect_equal(s$n_shots, 5)
  expect_equal(s$n_channels, 50)
})

test_that("ls_spectrum rejects mismatched lengths", {
  wl <- seq(200, 900, length.out = 10)
  expect_error(ls_spectrum(wl, 1:5), "equal")
})

test_that("ls_spectrum rejects NA wavelengths", {
  expect_error(ls_spectrum(c(1, NA, 3), c(1, 2, 3)))
})

test_that("print and summary methods work", {
  s <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1, n_channels = 100, n_shots = 3)
  expect_message(print(s), "libs_spectrum")
  expect_invisible(out <- summary(s))
})

test_that("Spectrum subsetting by wavelength range", {
  s <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1, n_channels = 200)
  sub <- s[c(300, 500)]
  expect_s3_class(sub, "libs_spectrum")
  expect_true(min(sub$wavelength) >= 300)
  expect_true(max(sub$wavelength) <= 500)
})

test_that("c.libs_spectrum combines shots", {
  s1 <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1, n_channels = 100, n_shots = 3)
  s2 <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 2, n_channels = 100, n_shots = 2)
  both <- c(s1, s2)
  expect_equal(both$n_shots, 5)
})

test_that("length and dim methods", {
  s <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1, n_channels = 64, n_shots = 4)
  expect_equal(length(s), 64)
  expect_equal(dim(s), c(4, 64))
})
