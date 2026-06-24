# Additional tests for R/quantify.R -------------------------------------------

test_that("ls_quantify validates calibration and x type", {
  ds <- ls_example_data("calibration", n_channels = 64)
  conc <- ds$sample_info$concentration
  cal <- ls_calibrate(ds, "Ca", 393.37, conc, verbose = FALSE)
  expect_error(ls_quantify(structure(list(), class = "x"), ds),
               "libs_calibration")
  expect_error(ls_quantify(cal, 42), "libs_spectrum")
})

test_that("ls_lod and ls_loq validate, handle pls, and use blank", {
  ds <- ls_example_data("calibration", n_channels = 128)
  conc <- ds$sample_info$concentration
  cal <- ls_calibrate(ds, "Ca", 393.37, conc, verbose = FALSE)

  expect_error(ls_lod(structure(list(), class = "x")), "libs_calibration")
  expect_gt(ls_lod(cal), 0)
  expect_gt(ls_loq(cal), ls_lod(cal))

  # blank-based LOD
  blank <- ds$spectra[[1]]
  expect_true(is.numeric(ls_lod(cal, blank = blank, window_nm = 1)))

  skip_if_not_installed("pls")
  cal_pls <- ls_calibrate(ds, "Ca", 393.37, conc, method = "pls",
                          n_components = 2, verbose = FALSE)
  expect_equal(ls_lod(cal_pls), cal_pls$lod)
})
