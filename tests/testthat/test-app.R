test_that("ls_run_app function exists and app files are installed", {
  expect_true(is.function(ls_run_app))
  # When run via devtools::load_all, system.file returns "" — skip
  # the path check in that case.
  path <- system.file("shiny", "libscanR", package = "libscanR")
  if (nzchar(path)) {
    expect_true(file.exists(file.path(path, "app.R")))
  }
})

# Exercise ls_run_app() without launching a Shiny server by mocking the
# (namespaced) shiny launch functions. All Suggests deps are available in the
# test environment and the app directory resolves via system.file, so the
# happy path through dependency + directory checks is exercised for real.

test_that("ls_run_app launches with mocked shiny when deps present", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  skip_if_not_installed("plotly")
  skip_if_not_installed("DT")
  called <- new.env()
  called$ran <- FALSE
  with_mocked_bindings(
    {
      res <- ls_run_app(launch.browser = FALSE)
      expect_null(res)
    },
    runApp = function(appDir, ...) {
      called$ran <- TRUE
      invisible(NULL)
    },
    shinyOptions = function(...) invisible(NULL),
    .package = "shiny"
  )
  expect_true(called$ran)
})

test_that("ls_run_app passes data through shinyOptions", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  skip_if_not_installed("plotly")
  skip_if_not_installed("DT")
  captured <- new.env()
  ds <- ls_example_data("tissue", n_channels = 32)
  with_mocked_bindings(
    ls_run_app(data = ds, launch.browser = FALSE),
    runApp = function(appDir, ...) invisible(NULL),
    shinyOptions = function(...) {
      captured$opts <- list(...)
      invisible(NULL)
    },
    .package = "shiny"
  )
  expect_true("libscanR.data" %in% names(captured$opts))
})

test_that("preloads validate and launch restores the previous Shiny option", {
  for (pkg in c("shiny", "bslib", "plotly", "DT")) skip_if_not_installed(pkg)
  previous <- shiny::getShinyOption("libscanR.data")
  withr::defer(shiny::shinyOptions(libscanR.data = previous))
  sentinel <- list(previous = TRUE)
  shiny::shinyOptions(libscanR.data = sentinel)
  spec <- ls_spectrum(c(400, 401), c(1, 2))
  with_mocked_bindings({
    ls_run_app(spec, launch.browser = FALSE)
    expect_identical(shiny::getShinyOption("libscanR.data"), sentinel)
  }, runApp = function(...) {
    expect_identical(shiny::getShinyOption("libscanR.data"), spec)
    NULL
  }, .package = "shiny")
  with_mocked_bindings({
    expect_error(ls_run_app(spec, launch.browser = FALSE), "launch failed")
    expect_identical(shiny::getShinyOption("libscanR.data"), sentinel)
  }, runApp = function(...) stop("launch failed"), .package = "shiny")
  expect_error(ls_run_app(list(invalid = TRUE)), class = "libscanR_app_input_error")
  expect_identical(shiny::getShinyOption("libscanR.data"), sentinel)
  tmp <- tempfile(fileext = ".csv")
  withr::defer(unlink(tmp))
  ls_write_csv(spec, tmp)
  expect_equal(.ls_app_data(tmp)$intensity, spec$intensity)
  spec$intensity[1] <- Inf
  expect_error(.ls_app_data(spec), "Invalid.*structure")
})

test_that("old optional UI dependencies fail before the app starts", {
  for (pkg in c("shiny", "bslib", "plotly", "DT")) skip_if_not_installed(pkg)
  current_version <- utils::packageVersion
  launched <- FALSE
  with_mocked_bindings({
    with_mocked_bindings({
      expect_error(ls_run_app(launch.browser = FALSE),
        "bslib.*0.5.0", class = "libscanR_app_dependency_error")
    }, packageVersion = function(pkg, ...) {
      if (identical(pkg, "bslib")) return(package_version("0.4.2"))
      current_version(pkg, ...)
    }, .package = "utils")
  }, runApp = function(...) { launched <<- TRUE }, .package = "shiny")
  expect_false(launched)
})
