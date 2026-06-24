# Additional tests for R/preprocess.R uncovered branches ----------------------

test_that("ls_normalize snv, area, and internal_std methods run", {
  s <- ls_simulate_spectrum(seed = 2, n_channels = 128)
  snv <- ls_normalize(s, method = "snv")
  expect_s3_class(snv, "libs_spectrum")
  area <- ls_normalize(s, method = "area")
  expect_s3_class(area, "libs_spectrum")
  istd <- ls_normalize(s, method = "internal_std",
                       ref_wavelength = 393.37, ref_window = 2)
  expect_s3_class(istd, "libs_spectrum")
})

test_that("ls_normalize internal_std requires ref and valid window", {
  s <- ls_simulate_spectrum(seed = 2, n_channels = 64)
  expect_error(ls_normalize(s, method = "internal_std"), "ref_wavelength")
  expect_error(
    ls_normalize(s, method = "internal_std", ref_wavelength = 99999,
                 ref_window = 0.001),
    "No channels within"
  )
})

test_that("ls_smooth savgol, gaussian, median methods run", {
  s <- ls_simulate_spectrum(seed = 1, n_channels = 128, noise_level = 0.1)
  for (m in c("savgol", "gaussian", "median")) {
    s2 <- ls_smooth(s, method = m, window = 9)
    expect_s3_class(s2, "libs_spectrum")
  }
})

test_that("ls_smooth even window is bumped to odd", {
  s <- ls_simulate_spectrum(seed = 1, n_channels = 64)
  s2 <- ls_smooth(s, method = "moving_avg", window = 8)
  expect_s3_class(s2, "libs_spectrum")
})

test_that("ls_crop errors when no channels in range", {
  s <- ls_simulate_spectrum(seed = 1, n_channels = 64)
  expect_error(ls_crop(s, min_nm = 5000, max_nm = 6000), "No channels fall")
})

test_that("ls_average_shots median and single-shot no-op", {
  s <- ls_simulate_spectrum(seed = 1, n_channels = 64, n_shots = 6)
  a <- ls_average_shots(s, method = "median")
  expect_equal(a$n_shots, 1)

  s1 <- ls_simulate_spectrum(seed = 1, n_channels = 64, n_shots = 1)
  a1 <- ls_average_shots(s1)
  expect_equal(a1$n_shots, 1)
})

test_that("ls_normalize and ls_smooth recurse on datasets", {
  ds <- ls_example_data("tissue", n_channels = 64)[1:3]
  expect_s3_class(ls_normalize(ds, method = "max"), "libs_dataset")
  expect_s3_class(ls_smooth(ds, method = "gaussian", window = 5),
                  "libs_dataset")
})

test_that("ls_gate_optimize ranks spectra by SNR", {
  spectra <- lapply(1:4, function(i) {
    s <- ls_simulate_spectrum(elements = c(Ca = 5000 * i), seed = i,
                              n_channels = 256)
    s$metadata$gate_delay_us <- i * 0.5
    s
  })
  res <- ls_gate_optimize(spectra, "Ca", 393.37, window_nm = 1)
  expect_s3_class(res, "tbl_df")
  expect_true(all(c("gate_delay_us", "snr", "sbr") %in% names(res)))
  expect_true(!is.null(attr(res, "recommended")))
})

test_that("ls_gate_optimize errors on non-list input", {
  expect_error(ls_gate_optimize(42, "Ca", 393.37), "non-empty list")
  expect_error(ls_gate_optimize(list(), "Ca", 393.37), "non-empty list")
})
