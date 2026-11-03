test_that("ls_dataset constructs from list of spectra", {
  specs <- lapply(1:3, function(i) {
    s <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = i, n_channels = 64)
    s$metadata$sample_id <- paste0("s", i)
    s
  })
  ds <- ls_dataset(specs)
  expect_s3_class(ds, "libs_dataset")
  expect_true(is_libs_dataset(ds))
  expect_equal(ds$n_spectra, 3)
  expect_equal(ds$n_channels, 64)
})

test_that("ls_dataset validates wavelength consistency", {
  s1 <- ls_simulate_spectrum(line_data = ls_demo_peaks(), n_channels = 64, seed = 1)
  s2 <- ls_simulate_spectrum(line_data = ls_demo_peaks(), n_channels = 128, seed = 2)
  expect_error(ls_dataset(list(s1, s2)), "inconsistent")
})

test_that("subset [.libs_dataset works", {
  ds <- ls_example_data("tissue", n_channels = 64)
  sub <- ds[1:5]
  expect_s3_class(sub, "libs_dataset")
  expect_equal(sub$n_spectra, 5)
})

test_that("print and summary work for dataset", {
  ds <- ls_example_data("tissue", n_channels = 64)
  expect_message(print(ds), "libs_dataset")
  expect_invisible(out <- summary(ds))
})

test_that("length and dim methods for dataset", {
  ds <- ls_example_data("tissue", n_channels = 64)
  expect_equal(length(ds), ds$n_spectra)
  expect_equal(dim(ds), c(ds$n_spectra, ds$n_channels))
})
