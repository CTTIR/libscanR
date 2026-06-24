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
