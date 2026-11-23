test_that("overlay colours every group when there are more than nine", {
  ds <- ls_example_data("tissue")[1:24]
  ds$sample_info$grp <- rep(letters[1:12], 2)
  p <- ls_plot_overlay(ds, color_by = "grp")
  built <- ggplot2::ggplot_build(p)
  expect_false(anyNA(built$data[[1]]$colour))
  expect_length(unique(built$data[[1]]$colour), 12L)
})

test_that("discrete group colours use the Okabe-Ito palette", {
  ds <- ls_example_data("tissue")
  pca <- ls_pca(ds, n_components = 3)
  p <- ls_plot_pca(pca, color_by = "tissue", ellipses = FALSE)
  cols <- unique(ggplot2::ggplot_build(p)$data[[1]]$colour)
  okabe_ito <- unname(grDevices::palette.colors(9L, palette = "Okabe-Ito"))
  expect_length(cols, 5L)
  expect_true(all(toupper(cols) %in% toupper(okabe_ito)))
})

test_that("confusion-matrix counts contrast with their tiles", {
  skip_if_not_installed("pls")
  ds <- ls_example_data("tissue")
  plsda <- ls_plsda(ds, "tissue", n_components = 3, validation = "none")
  p <- ls_plot_plsda(plsda, type = "confusion")
  text_layer <- ggplot2::ggplot_build(p)$data[[2]]
  counts <- as.numeric(text_layer$label)
  high <- counts > max(counts) / 2
  expect_true(all(text_layer$colour[high] == "black"))
  expect_true(all(text_layer$colour[!high] == "white"))
  expect_identical(p$scales$get_scales("fill")$name, "Count")
})

test_that("residual plot axes carry the concentration unit", {
  ds <- ls_example_data("calibration")
  cal <- ls_calibrate(ds, "Ca", 393.37, ds$sample_info$concentration,
                      verbose = FALSE)
  p <- ls_plot_residuals(cal)
  expect_identical(p$labels$x, paste0("Fitted concentration (", cal$unit, ")"))
  expect_identical(p$labels$y, paste0("Residual (", cal$unit, ")"))
})

test_that("loading labels skip overlapping text", {
  ds <- ls_example_data("tissue")
  pca <- ls_pca(ds, n_components = 2)
  p <- ls_plot_loadings(pca, pc = 1, n_top = 5)
  text_layer <- p$layers[[length(p$layers)]]
  expect_true(isTRUE(text_layer$geom_params$check_overlap))
  y_range <- ggplot2::ggplot_build(p)$layout$panel_params[[1]]$y.range
  expect_gt(y_range[2], max(pca$loadings[, 1]) +
              0.1 * diff(range(pca$loadings[, 1])))
})

test_that("peak SNR follows the documented median-referenced definition", {
  spec <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1)
  pk <- ls_find_peaks(spec, snr_threshold = 5)
  y <- libscanR:::.mean_intensity(spec)
  noise <- stats::mad(diff(y)) / sqrt(2)
  expect_equal(pk$snr, (pk$intensity - stats::median(y)) / noise)
})
