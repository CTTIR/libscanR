test_that("ls_calibrate produces linear fit with high R^2", {
  ds <- ls_example_data("calibration", n_channels = 512)
  conc <- ds$sample_info$concentration
  cal <- ls_calibrate(ds, "Ca", 393.37, conc, verbose = FALSE)
  expect_s3_class(cal, "libs_calibration")
  expect_gt(cal$r_squared, 0.8)
  expect_true(!is.null(cal$lod))
})

test_that("predict.libs_calibration returns numeric predictions", {
  ds <- ls_example_data("calibration", n_channels = 256)
  conc <- ds$sample_info$concentration
  cal <- ls_calibrate(ds, "Ca", 393.37, conc, verbose = FALSE)
  pred <- predict(cal, newdata = cal$intensities)
  expect_type(pred, "double")
  expect_length(pred, length(cal$intensities))
})

test_that("ls_lod and ls_loq return positive values", {
  ds <- ls_example_data("calibration", n_channels = 256)
  conc <- ds$sample_info$concentration
  cal <- ls_calibrate(ds, "Ca", 393.37, conc, verbose = FALSE)
  lod <- ls_lod(cal)
  loq <- ls_loq(cal)
  expect_gt(lod, 0)
  expect_gt(loq, lod)
})

test_that("ls_saha_boltzmann returns a tibble with temperature", {
  # The display simulator is not a physical plasma forward model.
  env <- new.env(parent = globalenv())
  sys.source(system.file("examples", "saha-boltzmann-synthetic.R", package = "libscanR"),
              envir = env)
  res <- do.call(ls_saha_boltzmann, env$saha_synthetic_example())
  expect_s3_class(res, "tbl_df")
  expect_equal(res$temperature_k, rep(10000, 2), tolerance = 1e-8)
  expect_equal(res$concentration_rel, c(.7, .3), tolerance = 1e-10)
})

test_that("print.libs_calibration does not error", {
  ds <- ls_example_data("calibration", n_channels = 256)
  conc <- ds$sample_info$concentration
  cal <- ls_calibrate(ds, "Ca", 393.37, conc, verbose = FALSE)
  expect_message(print(cal), "libs_calibration")
})
