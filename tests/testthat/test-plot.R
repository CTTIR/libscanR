test_that("ls_plot_spectrum returns a ggplot", {
  s <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1, n_channels = 128)
  p <- ls_plot_spectrum(s)
  expect_s3_class(p, "ggplot")
})

test_that("ls_plot_spectrum with peaks and elements works", {
  withr::local_options(list(libscanR.element_db = synthetic_reference_file()))
  s <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1, n_channels = 256)
  p <- ls_plot_spectrum(s, show_peaks = TRUE, show_elements = "Ca",
                        snr_threshold = 3)
  expect_s3_class(p, "ggplot")
})

test_that("ls_plot_overlay works on dataset", {
  ds <- ls_example_data("tissue", n_channels = 64)[1:10]
  p <- ls_plot_overlay(ds, color_by = "tissue")
  expect_s3_class(p, "ggplot")
})

test_that("ls_plot_calibration returns ggplot", {
  ds <- ls_example_data("calibration", n_channels = 128)
  conc <- ds$sample_info$concentration
  cal <- ls_calibrate(ds, "Ca", 393.37, conc, verbose = FALSE)
  p <- ls_plot_calibration(cal)
  expect_s3_class(p, "ggplot")
})

test_that("ls_plot_residuals returns ggplot", {
  ds <- ls_example_data("calibration", n_channels = 128)
  conc <- ds$sample_info$concentration
  cal <- ls_calibrate(ds, "Ca", 393.37, conc, verbose = FALSE)
  p <- ls_plot_residuals(cal)
  expect_s3_class(p, "ggplot")
})

test_that("ls_plot_map returns ggplot", {
  ds <- ls_example_data("spatial", n_channels = 64)
  m <- ls_build_map(ds, "Ca", 393.37)
  p <- ls_plot_map(m)
  expect_s3_class(p, "ggplot")
})

test_that("ls_plot_map_panel returns ggplot", {
  ds <- ls_example_data("spatial", n_channels = 64)
  ms <- ls_map_elements(ds, c("Ca", "Fe"),
                        c(Ca = 393.37, Fe = 371.99))
  p <- ls_plot_map_panel(ms)
  expect_s3_class(p, "ggplot")
})

test_that("PCA plots return ggplot", {
  ds <- ls_example_data("tissue", n_channels = 64)
  pca <- ls_pca(ds, n_components = 3)
  expect_s3_class(ls_plot_pca(pca, color_by = "tissue"), "ggplot")
  expect_s3_class(ls_plot_loadings(pca, pc = 1), "ggplot")
  expect_s3_class(ls_plot_scree(pca), "ggplot")
})

test_that("ls_plot_region works", {
  s <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1, n_channels = 256)
  p <- ls_plot_region(s, 380, 450)
  expect_s3_class(p, "ggplot")
})

test_that("theme_libs returns a ggplot theme", {
  t <- theme_libs()
  expect_s3_class(t, "theme")
})
