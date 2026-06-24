# Tests for R/plot-utils.R ----------------------------------------------------

test_that("theme_libs returns a ggplot theme", {
  th <- theme_libs(base_size = 10)
  expect_s3_class(th, "theme")
  expect_s3_class(th, "gg")
})

test_that("scale_color_wavelength returns a ggplot scale", {
  sc <- scale_color_wavelength()
  expect_s3_class(sc, "ScaleContinuous")
  sc2 <- scale_color_wavelength(name = "WL")
  expect_s3_class(sc2, "Scale")
})

test_that("scale_color_wavelength composes into a plot without error", {
  df <- data.frame(x = 1:5, y = 1:5, wl = seq(300, 700, length.out = 5))
  p <- ggplot2::ggplot(df, ggplot2::aes(x, y, colour = wl)) +
    ggplot2::geom_point() +
    scale_color_wavelength() +
    theme_libs()
  built <- ggplot2::ggplot_build(p)
  expect_s3_class(built, "ggplot_built")
})
