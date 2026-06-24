# Additional tests for plotting branches --------------------------------------

# --- plot-calibration.R ------------------------------------------------------

test_that("ls_plot_calibration toggles and PLS warning + residual paths", {
  ds <- ls_example_data("calibration", n_channels = 128)
  conc <- ds$sample_info$concentration
  cal <- ls_calibrate(ds, "Ca", 393.37, conc, verbose = FALSE)
  p <- ls_plot_calibration(cal, show_lod = FALSE, show_loq = FALSE,
                           show_prediction_interval = FALSE)
  expect_s3_class(p, "ggplot")

  expect_error(ls_plot_calibration(structure(list(), class = "x")),
               "libs_calibration")
  expect_error(ls_plot_residuals(structure(list(), class = "x")),
               "libs_calibration")

  skip_if_not_installed("pls")
  cal_pls <- ls_calibrate(ds, "Ca", 393.37, conc, method = "pls",
                          n_components = 2, verbose = FALSE)
  expect_warning(ls_plot_calibration(cal_pls), "PLS")
  expect_s3_class(ls_plot_residuals(cal_pls), "ggplot")
})

# --- plot-chemometrics.R -----------------------------------------------------

test_that("ls_plot_pca without color and ellipses off, validation errors", {
  ds <- ls_example_data("tissue", n_channels = 64)
  pca <- ls_pca(ds, n_components = 3)
  expect_s3_class(ls_plot_pca(pca), "ggplot")
  expect_s3_class(ls_plot_pca(pca, color_by = "tissue", ellipses = FALSE),
                  "ggplot")
  expect_error(ls_plot_pca(structure(list(), class = "x")), "libs_pca")
  expect_error(ls_plot_pca(pca, pc_x = 99), "exceed")
  expect_error(ls_plot_pca(pca, color_by = "nope"), "not found")
})

test_that("ls_plot_loadings validates and n_top zero path", {
  ds <- ls_example_data("tissue", n_channels = 64)
  pca <- ls_pca(ds, n_components = 3)
  expect_s3_class(ls_plot_loadings(pca, pc = 2, n_top = 0), "ggplot")
  expect_error(ls_plot_loadings(structure(list(), class = "x")), "libs_pca")
  expect_error(ls_plot_scree(structure(list(), class = "x")), "libs_pca")
})

test_that("ls_plot_plsda scores/confusion/vip and validation error", {
  skip_if_not_installed("pls")
  ds <- ls_example_data("tissue", n_channels = 64)
  plsda <- ls_plsda(ds, "tissue", n_components = 3, validation = "none")
  expect_s3_class(ls_plot_plsda(plsda, type = "scores"), "ggplot")
  expect_s3_class(ls_plot_plsda(plsda, type = "confusion"), "ggplot")
  expect_s3_class(ls_plot_plsda(plsda, type = "vip"), "ggplot")
  expect_error(ls_plot_plsda(structure(list(), class = "x")), "libs_plsda")
})

# --- plot-map.R --------------------------------------------------------------

test_that("ls_plot_map handles all colour scales and irregular grids", {
  ds <- ls_example_data("spatial", n_channels = 64)
  m <- ls_build_map(ds, "Ca", 393.37)
  for (sc in c("viridis", "magma", "plasma", "inferno", "hot", "jet")) {
    expect_s3_class(ls_plot_map(m, color_scale = sc), "ggplot")
  }
  expect_s3_class(ls_plot_element_map(m), "ggplot")
  expect_error(ls_plot_map(structure(list(), class = "x")), "libs_map")

  # irregular map (drop grid) -> geom_point path
  m_irr <- m
  m_irr$grid <- NULL
  expect_s3_class(ls_plot_map(m_irr), "ggplot")
})

test_that("ls_plot_map_panel validates inputs", {
  ds <- ls_example_data("spatial", n_channels = 64)
  ms <- ls_map_elements(ds, c("Ca", "Fe"), c(Ca = 393.37, Fe = 371.99))
  expect_s3_class(ls_plot_map_panel(ms), "ggplot")
  expect_error(ls_plot_map_panel(list()), "non-empty list")
  expect_error(ls_plot_map_panel(list(1, 2)), "must be")
})
