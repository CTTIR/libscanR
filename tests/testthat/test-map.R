test_that("ls_build_map constructs libs_map", {
  ds <- ls_example_data("spatial", n_channels = 128)
  m <- ls_build_map(ds, "Ca", 393.37)
  expect_s3_class(m, "libs_map")
  expect_equal(length(m$values), ds$n_spectra)
  expect_equal(m$element, "Ca")
})

test_that("ls_build_map builds a grid for regular coordinates", {
  ds <- ls_example_data("spatial", n_channels = 128)
  m <- ls_build_map(ds, "Ca", 393.37)
  expect_false(is.null(m$grid))
  expect_equal(dim(m$grid), c(20, 20))
})

test_that("ls_map_elements returns list of maps", {
  ds <- ls_example_data("spatial", n_channels = 128)
  ms <- ls_map_elements(ds, c("Ca", "Fe"),
                        c(Ca = 393.37, Fe = 371.99))
  expect_type(ms, "list")
  expect_length(ms, 2)
  expect_s3_class(ms[["Ca"]], "libs_map")
})


test_that("large irregular coordinates do not overflow grid detection", {
  # Isolate map assembly from repeated spectral validation/integration; those
  # contracts are exercised by the real-spectrum mapping tests above.
  local_mocked_bindings(
    .validate_dataset = function(x) invisible(TRUE),
    ls_peak_area = function(s, line_nm, window_nm) as.double(s),
    .package = "libscanR"
  )
  n <- 47000L
  coordinates <- seq_len(n)
  dataset <- list(
    sample_info = data.frame(x_pos = coordinates, y_pos = coordinates),
    spectra = as.list(coordinates)
  )
  expect_warning(map <- ls_build_map(dataset, "fixture", 2), NA)
  expect_null(map$grid)
  expect_identical(map$x, coordinates)
  expect_identical(map$y, coordinates)
  expect_identical(map$values, as.double(coordinates))
})
