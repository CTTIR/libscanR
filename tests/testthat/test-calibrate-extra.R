# Additional tests for R/calibrate.R and R/libs_calibration-class.R -----------

test_that("ls_calibrate errors on length mismatch and cf_libs", {
  ds <- ls_example_data("calibration", n_channels = 64)
  conc <- ds$sample_info$concentration
  expect_error(ls_calibrate(ds, "Ca", 393.37, conc[1:3], verbose = FALSE),
               "must match number of spectra")
  expect_error(ls_calibrate(ds, "Ca", 393.37, conc, method = "cf_libs",
                            verbose = FALSE),
               "ls_saha_boltzmann")
})

test_that("ls_calibrate internal_std requires reference line", {
  ds <- ls_example_data("calibration", n_channels = 128)
  conc <- ds$sample_info$concentration
  expect_error(
    ls_calibrate(ds, "Ca", 393.37, conc, method = "internal_std",
                 verbose = FALSE),
    "internal_std_nm"
  )
  cal <- ls_calibrate(ds, "Ca", 393.37, conc, method = "internal_std",
                      internal_std_nm = 589.0, verbose = FALSE)
  expect_s3_class(cal, "libs_calibration")
})

test_that("ls_calibrate pls method runs and is verbose", {
  skip_if_not_installed("pls")
  ds <- ls_example_data("calibration", n_channels = 256)
  conc <- ds$sample_info$concentration
  expect_message(
    cal <- ls_calibrate(ds, "Ca", 393.37, conc, method = "pls",
                        n_components = 3, verbose = TRUE),
    "PLS"
  )
  expect_equal(cal$method, "pls")
})

test_that("ls_calibrate is verbose for univariate", {
  ds <- ls_example_data("calibration", n_channels = 64)
  conc <- ds$sample_info$concentration
  expect_message(ls_calibrate(ds, "Ca", 393.37, conc, verbose = TRUE), "R2")
})

test_that("ls_saha_boltzmann errors for unnamed lines and all-fail", {
  s <- ls_simulate_spectrum(elements = c(Ca = 10000), seed = 3,
                            n_channels = 512)
  s <- ls_baseline(s, method = "snip", iterations = 30)
  expect_error(ls_saha_boltzmann(s, elements = "Ca", lines_nm = list(123)),
               "named list")
  # element not in DB / no usable lines -> abort
  expect_error(
    ls_saha_boltzmann(s, elements = "Ca",
                      lines_nm = list(Ca = c(99990, 99991)), verbose = FALSE),
    "No element quantified"
  )
})

test_that(".r_squared returns NA when total SS is zero", {
  expect_true(is.na(.r_squared(c(5, 5, 5), c(5, 5, 5))))
  expect_equal(.r_squared(c(1, 2, 3), c(1, 2, 3)), 1)
})

# --- libs_calibration-class.R -----------------------------------------------

test_that("ls_calibration validates its inputs", {
  expect_error(ls_calibration(c("a", "b"), 393, 1:3, 1:3,
                              model = NULL), "single character")
  expect_error(ls_calibration("Ca", c(1, 2), 1:3, 1:3, model = NULL),
               "single numeric")
  expect_error(ls_calibration("Ca", 393, 1:3, 1:2, model = NULL),
               "equal length")
})

test_that("is_libs_calibration and summary work", {
  ds <- ls_example_data("calibration", n_channels = 64)
  conc <- ds$sample_info$concentration
  cal <- ls_calibrate(ds, "Ca", 393.37, conc, verbose = FALSE)
  expect_true(is_libs_calibration(cal))
  expect_false(is_libs_calibration(list()))
  s <- summary(cal)
  expect_true(is.list(s))
  expect_equal(s$element, "Ca")
})

test_that("predict.libs_calibration errors on no model and unsupported method", {
  ds <- ls_example_data("calibration", n_channels = 64)
  conc <- ds$sample_info$concentration
  cal <- ls_calibrate(ds, "Ca", 393.37, conc, verbose = FALSE)

  cal_nomodel <- cal
  cal_nomodel$model <- NULL
  expect_error(predict(cal_nomodel, newdata = 1:3), "no fitted model")

  cal_bad <- cal
  cal_bad$method <- "cf_libs"
  expect_error(predict(cal_bad, newdata = 1:3), "Unsupported calibration method")
})

test_that("predict.libs_calibration works for pls method", {
  skip_if_not_installed("pls")
  ds <- ls_example_data("calibration", n_channels = 128)
  conc <- ds$sample_info$concentration
  cal <- ls_calibrate(ds, "Ca", 393.37, conc, method = "pls",
                      n_components = 2, verbose = FALSE)
  # PLS prediction needs the full spectral-window matrix used for training.
  X <- cal$model$model$X
  pred <- predict(cal, newdata = X)
  expect_type(pred, "double")
  expect_equal(length(pred), nrow(X))
})
