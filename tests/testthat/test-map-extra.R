# Additional tests for R/map.R ------------------------------------------------

test_that("ls_build_map errors without x_pos / y_pos", {
  ds <- ls_example_data("tissue", n_channels = 64)  # no x_pos/y_pos
  expect_error(ls_build_map(ds, "Ca", 393.37), "x_pos")
})

test_that("ls_build_map applies a calibration and updates unit", {
  ds <- ls_example_data("spatial", n_channels = 128)
  cd <- ls_example_data("calibration", n_channels = 128)
  cal <- ls_calibrate(cd, "Ca", 393.37, cd$sample_info$concentration,
                      verbose = FALSE)
  m <- ls_build_map(ds, "Ca", 393.37, calibration = cal)
  expect_s3_class(m, "libs_map")
  expect_equal(m$unit, cal$unit)
})

test_that("ls_build_map handles irregular coordinates (grid NULL)", {
  ds <- ls_example_data("spatial", n_channels = 64)
  # corrupt one coordinate so grid is irregular
  ds$sample_info$x_pos[1] <- 999
  m <- ls_build_map(ds, "Ca", 393.37)
  expect_null(m$grid)
})

test_that("ls_map_elements errors on unnamed lines vector", {
  ds <- ls_example_data("spatial", n_channels = 64)
  expect_error(ls_map_elements(ds, c("Ca", "Fe"), c(393.37, 371.99)),
               "named numeric vector")
})

test_that("print.libs_map reports grid and irregular cases", {
  ds <- ls_example_data("spatial", n_channels = 64)
  m <- ls_build_map(ds, "Ca", 393.37)
  expect_message(print(m), "Element")
  m$grid <- NULL
  expect_message(print(m), "irregular")
})
