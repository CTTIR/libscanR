#' Launch the libscanR Shiny Application
#'
#' Starts an interactive Shiny application for exploring, preprocessing, and
#' analyzing LIBS spectral data. The app provides six tabs: Import,
#' Preprocessing, Peaks, Calibration, Chemometrics, and Export.
#'
#' @param data Optional. A [ls_spectrum()], [ls_dataset()], or file path to
#'   preload. Objects and files are validated before starting the app.
#'   Default `NULL` (start with upload interface).
#' @param port Integer. Port for the app. Default `NULL` (auto-select).
#' @param launch.browser Logical. Open browser on launch. Default `TRUE`.
#'
#' @details Upload batches are admitted together: invalid files leave the
#'   previously loaded data intact. Original upload names identify their source.
#'   New data and successful preprocessing invalidate downstream analysis
#'   results. Preprocessing controls take effect only after Apply; a failed
#'   operation retains the last successful data, and Reset restores raw data.
#'
#'   The complete ZIP download contains one CSV per spectrum and, for a dataset,
#'   `sample_info.csv`. Spectrum CSV files retain all shots, baseline and
#'   supported metadata through [ls_write_csv()]. ZIP creation requires an
#'   external `zip` command on `PATH` (or configured through `R_ZIPCMD`),
#'   including on Windows. The separate wide dataset CSV
#'   contains mean intensities only. Calibration CSV files summarize figures of
#'   merit rather than storing reusable prediction models. Load a labelled
#'   [ls_dataset()] through `data` for analyses requiring concentration or class
#'   columns in `sample_info`.
#'
#'   Example datasets use explicitly fictional teaching peaks and concentrations,
#'   not an atomic reference or experimental measurements. Peak detection and
#'   raw plots work without a reference. Optional element annotations require
#'   a user-supplied file configured for [ls_element_db()]; missing or invalid
#'   references leave raw detections available and report the annotation error.
#'   Peak and calibration CSVs carry `data_origin = "explicit_synthetic_peaks"`
#'   for wholly fictional inputs; mixed calibration inputs carry
#'   `"includes_explicit_synthetic_peaks"`. Peak exports follow the first
#'   spectrum actually used for detection.
#'
#'   The previous application data option is restored when the app stops or
#'   startup fails. Each browser session keeps its own working data and results.
#'
#' @return Invisible `NULL`. Launches a Shiny application as a side effect.
#'
#' @examples
#' \donttest{
#' if (interactive()) {
#'   ls_run_app()
#' }
#' }
#' @export
ls_run_app <- function(data = NULL, port = NULL, launch.browser = TRUE) {
  needed <- c("shiny", "bslib", "plotly", "DT")
  missing_pkgs <- needed[!vapply(needed, requireNamespace,
                                 logical(1), quietly = TRUE)]
  if (length(missing_pkgs) > 0) {
    cli::cli_abort(c(
      "The Shiny app needs the following package(s) to run:",
      "i" = "{.pkg {missing_pkgs}}",
      "i" = "Install with: {.code install.packages(c({paste0('\"', missing_pkgs, '\"', collapse = ', ')}))}"
    ))
  }
  minimums <- c(shiny = "1.6.0", bslib = "0.5.0")
  for (pkg in names(minimums)) {
    if (utils::packageVersion(pkg) < minimums[[pkg]]) {
      cli::cli_abort("The Shiny app requires {.pkg {pkg}} >= {minimums[[pkg]]}; update it before launching.",
                     class = "libscanR_app_dependency_error")
    }
  }
  app_dir <- system.file("shiny", "libscanR", package = "libscanR")
  if (!nzchar(app_dir)) {
    cli::cli_abort(c(
      "Could not find the Shiny app directory.",
      "i" = "Try re-installing {.pkg libscanR}."
    ))
  }
  data <- .ls_app_data(data)
  previous <- shiny::getShinyOption("libscanR.data", default = NULL)
  on.exit(shiny::shinyOptions(libscanR.data = previous), add = TRUE)
  shiny::shinyOptions(libscanR.data = data)
  shiny::runApp(app_dir, port = port,
                launch.browser = launch.browser,
                display.mode = "normal")
  invisible(NULL)
}

.ls_app_data <- function(data) {
  if (is.null(data)) return(NULL)
  if (is.character(data) && length(data) == 1L && !is.na(data)) {
    data <- ls_read_auto(data, verbose = FALSE)
  }
  if (inherits(data, "libs_spectrum")) {
    .validate_spectrum(data)
  } else if (inherits(data, "libs_dataset")) {
    .validate_dataset(data)
  } else {
    cli::cli_abort("{.arg data} must be a LIBS spectrum, dataset, or one readable file path.",
                   class = "libscanR_app_input_error")
  }
  data
}
