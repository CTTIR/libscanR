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

# WCAG 2 relative luminance and contrast ratio, used only to judge the labels.
wcag_contrast <- function(a, b) {
  lum <- function(col) {
    v <- grDevices::col2rgb(col) / 255
    v <- ifelse(v <= 0.04045, v / 12.92, ((v + 0.055) / 1.055)^2.4)
    colSums(v * c(0.2126, 0.7152, 0.0722))
  }
  la <- lum(a)
  lb <- lum(b)
  (pmax(la, lb) + 0.05) / (pmin(la, lb) + 0.05)
}

# Every count label must use whichever of black or white contrasts more with
# the tile colour it is drawn on.
expect_legible_counts <- function(p) {
  built <- ggplot2::ggplot_build(p)
  tiles <- built$data[[1]]
  text_layer <- built$data[[2]]
  key <- function(d) paste(d$x, d$y)
  fill <- tiles$fill[match(key(text_layer), key(tiles))]
  other <- ifelse(text_layer$colour == "black", "white", "black")
  expect_true(all(wcag_contrast(text_layer$colour, fill) >=
                    wcag_contrast(other, fill)))
  expect_true(all(wcag_contrast(text_layer$colour, fill) >= 4.5))
}

with_confusion <- function(plsda, counts) {
  lv <- c("a", "b")
  plsda$confusion_matrix <- as.table(matrix(
    as.integer(counts), 2L, dimnames = list(observed = lv, predicted = lv)))
  plsda
}

test_that("confusion-matrix counts contrast with their tiles", {
  skip_if_not_installed("pls")
  ds <- ls_example_data("tissue")
  plsda <- ls_plsda(ds, "tissue", n_components = 3, validation = "none")
  p <- ls_plot_plsda(plsda, type = "confusion")
  expect_legible_counts(p)
  expect_identical(p$scales$get_scales("fill")$name, "Count")
})

test_that("confusion-matrix counts stay legible when no cell is empty", {
  skip_if_not_installed("pls")
  ds <- ls_example_data("tissue")
  plsda <- ls_plsda(ds, "tissue", n_components = 3, validation = "none")
  # A near-chance classifier: the smallest count is far above half the largest,
  # yet its tile is the darkest colour of the scale.
  near_chance <- with_confusion(plsda, c(22, 28, 25, 25))
  p <- ls_plot_plsda(near_chance, type = "confusion")
  expect_legible_counts(p)
  text_layer <- ggplot2::ggplot_build(p)$data[[2]]
  expect_identical(text_layer$colour[text_layer$label == "22"], "white")
  expect_identical(text_layer$colour[text_layer$label == "28"], "black")
  # Equal counts share the mid-scale tile colour.
  expect_legible_counts(ls_plot_plsda(with_confusion(plsda, rep(25, 4)),
                                      type = "confusion"))
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
