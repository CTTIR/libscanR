test_that("calibration plots show prediction intervals from the actual saved fit", {
  response <- c(2, 4, 5, 8, 11)
  concentration <- 1:5
  model <- stats::lm(concentration ~ response)
  cal <- ls_calibration("X", 500, concentration, response, model,
                        lod = NA_real_, loq = NA_real_)
  p <- ls_plot_calibration(cal)
  built <- ggplot2::ggplot_build(p)
  ribbon <- built$data[[1L]]
  prediction <- stats::predict(model, data.frame(response = ribbon$x), interval = "prediction")
  confidence <- stats::predict(model, data.frame(response = ribbon$x), interval = "confidence")
  expect_equal(ribbon$ymin, unname(prediction[, "lwr"]))
  expect_equal(ribbon$ymax, unname(prediction[, "upr"]))
  expect_true(all(ribbon$ymax - ribbon$ymin > confidence[, "upr"] - confidence[, "lwr"]))
  expect_equal(built$data[[2L]]$y, unname(prediction[, "fit"]))
  expect_length(built$data, 3L)
  expect_identical(p$labels$x, "Integrated peak response (a.u. nm)")
  expect_length(ggplot2::ggplot_build(ls_plot_calibration(cal, show_prediction_interval = FALSE))$data, 2L)
})

test_that("PLS plot coordinates are full-model training predictions", {
  skip_if_not_installed("pls")
  ds <- ls_example_data("calibration", n_channels = 256)
  cal <- ls_calibrate(ds, "Ca", 393.37, ds$sample_info$concentration,
                      method = "pls", n_components = 2, verbose = FALSE)
  p <- ls_plot_calibration(cal)
  data <- ggplot2::ggplot_build(p)$data[[1L]]
  expect_equal(data$x, cal$concentrations)
  expected <- as.numeric(stats::fitted(cal$model)[, , cal$model$ncomp])
  expect_equal(data$y, expected)
  expect_match(p$labels$y, "Training fitted concentration", fixed = TRUE)
  expect_match(p$labels$subtitle, "unavailable", fixed = TRUE)
})

test_that("calibrated maps reuse fitted integration and identity contracts", {
  response <- c(2, 4, 5, 8, 11)
  ds <- ls_dataset(lapply(seq_along(response), function(i) {
    ls_spectrum(c(499, 500, 501), c(0, response[i], 0),
                list(sample_id = paste0("s", i)))
  }))
  ds$sample_info$x_pos <- 1:5
  ds$sample_info$y_pos <- 0
  cal <- ls_calibrate(ds, "X", 500, 1:5, window_nm = 2, verbose = FALSE)
  expected <- ls_quantify(cal, ds)$concentration
  expect_equal(ls_build_map(ds, "X", 500, calibration = cal)$values, expected)
  expect_equal(ls_map_elements(ds, "X", c(X = 500), list(X = cal))$X$values, expected)
  expect_error(ls_build_map(ds, "X", 500, calibration = cal, window_nm = 1), "fitted integration window")
  expect_identical(ls_build_map(ds, "X", 500)$unit, "a.u. nm")
})
