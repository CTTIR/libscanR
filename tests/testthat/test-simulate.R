test_that("ls_simulate_spectrum returns libs_spectrum", {
  s <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1, n_channels = 128, n_shots = 3)
  expect_s3_class(s, "libs_spectrum")
  expect_equal(s$n_channels, 128)
  expect_equal(s$n_shots, 3)
})

test_that("ls_simulate_spectrum seed is reproducible", {
  s1 <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 42, n_channels = 64)
  s2 <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 42, n_channels = 64)
  expect_equal(s1$intensity, s2$intensity)
})

test_that("ls_example_data works for all scenarios", {
  t <- ls_example_data("tissue", n_channels = 64)
  expect_s3_class(t, "libs_dataset")
  expect_equal(t$n_spectra, 50)

  c <- ls_example_data("calibration", n_channels = 64)
  expect_s3_class(c, "libs_dataset")
  expect_true("concentration" %in% names(c$sample_info))

  sp <- ls_example_data("spatial", n_channels = 64)
  expect_s3_class(sp, "libs_dataset")
  expect_true(all(c("x_pos", "y_pos") %in% names(sp$sample_info)))
})

test_that("ls_example_data('all') returns a named list", {
  all_data <- ls_example_data("all", n_channels = 64)
  expect_type(all_data, "list")
  expect_true(all(c("tissue", "calibration", "spatial") %in% names(all_data)))
})
