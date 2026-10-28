# libscanR Shiny Application
# Do not call library() here — use namespace-qualified functions.

# Source module files from the same directory tree
.module_dir <- file.path(
  system.file("shiny", "libscanR", package = "libscanR"),
  "modules"
)
if (!nzchar(.module_dir) || !dir.exists(.module_dir)) {
  # Fallback when running via runApp() from the installed location
  .module_dir <- file.path(getwd(), "modules")
}
for (.f in list.files(.module_dir, pattern = "\\.R$", full.names = TRUE)) {
  source(.f, local = TRUE)
}

ui <- bslib::page_navbar(
  title = "libscanR",
  theme = bslib::bs_theme(
    version = 5,
    bootswatch = "flatly",
    primary = "#2E86AB",
    secondary = "#A23B72",
    "font-scale" = 0.9
  ),
  header = shiny::tags$head(
    shiny::tags$link(rel = "stylesheet", href = "custom.css")
  ),
  bslib::nav_panel("Import", mod_import_ui("import")),
  bslib::nav_panel("Preprocess", mod_preprocess_ui("preprocess")),
  bslib::nav_panel("Peaks", mod_peaks_ui("peaks")),
  bslib::nav_panel("Calibration", mod_calibration_ui("calibration")),
  bslib::nav_panel("Chemometrics", mod_chemometrics_ui("chemometrics")),
  bslib::nav_panel("Export", mod_export_ui("export")),
  bslib::nav_spacer(),
  bslib::nav_item(
    shiny::tags$a(
      utils::getFromNamespace(".cttir_brand_logo", "libscanR")(),
      href = "https://github.com/r-heller/libscanR",
      target = "_blank"
    )
  )
)

server <- function(input, output, session) {
  rv <- shiny::reactiveValues(
    raw_data = shiny::getShinyOption("libscanR.data", default = NULL),
    processed_data = NULL,
    peaks = NULL,
    calibrations = list(),
    pca_result = NULL,
    plsda_result = NULL
  )

  # If preloaded data was given as a file path, try to import it
  shiny::observeEvent(rv$raw_data, {
    if (is.character(rv$raw_data) && length(rv$raw_data) == 1 &&
        file.exists(rv$raw_data)) {
      rv$raw_data <- tryCatch(libscanR::ls_read_auto(rv$raw_data, verbose = FALSE),
                              error = function(e) NULL)
    }
  }, once = TRUE)

  mod_import_server("import", rv)
  mod_preprocess_server("preprocess", rv)
  mod_peaks_server("peaks", rv)
  mod_calibration_server("calibration", rv)
  mod_chemometrics_server("chemometrics", rv)
  mod_export_server("export", rv)
}

shiny::shinyApp(ui, server)
