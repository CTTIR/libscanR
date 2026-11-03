# Import module
mod_import_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      title = "Data import",
      shiny::selectInput(ns("format"), "Format",
                         choices = c("Auto-detect" = "auto",
                                     "Generic CSV/TSV" = "generic",
                                     "SciAps" = "sciaps",
                                     "Applied Spectra" = "aurora")),
      shiny::fileInput(ns("file"), "Upload spectrum (CSV/TSV/TXT)",
                       accept = c(".csv", ".tsv", ".txt"),
                       multiple = TRUE),
      shiny::helpText("Files must share a wavelength axis and have distinct sample IDs. A failed batch leaves the previous data loaded."),
      shiny::hr(),
      shiny::strong("Or load fictional teaching data:"),
      shiny::actionButton(ns("load_tissue"), "Tissue dataset",
                          class = "btn-outline-primary w-100"),
      shiny::actionButton(ns("load_cal"), "Calibration dataset",
                          class = "btn-outline-primary w-100 mt-2"),
      shiny::actionButton(ns("load_spatial"), "Spatial dataset",
                          class = "btn-outline-primary w-100 mt-2")
    ),
    bslib::card(
      fill = FALSE,
      bslib::card_header("Import status"),
      shiny::uiOutput(ns("status"))
    ),
    bslib::card(
      bslib::card_header("Preview"),
      plotly::plotlyOutput(ns("preview"), height = "400px")
    ),
    bslib::card(
      bslib::card_header("Sample info"),
      DT::DTOutput(ns("info"))
    )
  )
}

mod_import_server <- function(id, rv) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    shiny::observeEvent(input$file, {
      shiny::req(input$file)
      result <- .ls_app_attempt(.ls_app_upload(input$file, input$format),
        function(text) rv$import_error <- text)
      if (result$ok) {
        .ls_app_admit(rv, result$value)
      }
    })

    shiny::observeEvent(input$load_tissue, {
      .ls_app_admit(rv, libscanR::ls_example_data("tissue"))
    })
    shiny::observeEvent(input$load_cal, {
      .ls_app_admit(rv, libscanR::ls_example_data("calibration"))
    })
    shiny::observeEvent(input$load_spatial, {
      .ls_app_admit(rv, libscanR::ls_example_data("spatial"))
    })

    output$status <- shiny::renderUI({
      error <- if (!is.null(rv$import_error)) {
        paste(rv$import_error, if (is.null(rv$raw_data)) "No data are loaded."
              else "The previously loaded data are retained.")
      } else NULL
      if (is.null(rv$raw_data)) {
        return(.ls_app_status(error %||%
          "No data loaded yet. Upload a spectrum or load an example."))
      }
      if (inherits(rv$raw_data, "libs_spectrum")) {
        txt <- sprintf("Spectrum loaded: %d channels, %d shots, range %.1f-%.1f nm.",
                       rv$raw_data$n_channels, rv$raw_data$n_shots,
                       rv$raw_data$range_nm[1], rv$raw_data$range_nm[2])
      } else {
        txt <- sprintf("Dataset loaded: %d spectra, %d channels, range %.1f-%.1f nm.",
                       rv$raw_data$n_spectra, rv$raw_data$n_channels,
                       rv$raw_data$range_nm[1], rv$raw_data$range_nm[2])
      }
      .ls_app_status(paste(c(error, txt, .ls_app_teaching_note(rv$raw_data)), collapse = " "))
    })

    output$preview <- plotly::renderPlotly({
      shiny::req(rv$raw_data)
      if (inherits(rv$raw_data, "libs_spectrum")) {
        p <- libscanR::ls_plot_spectrum(rv$raw_data)
      } else {
        n <- min(10, rv$raw_data$n_spectra)
        p <- libscanR::ls_plot_overlay(rv$raw_data[seq_len(n)],
                                       color_by = NULL)
      }
      plotly::ggplotly(p)
    })

    output$info <- DT::renderDT({
      shiny::req(rv$raw_data)
      if (inherits(rv$raw_data, "libs_spectrum")) {
        df <- data.frame(
          key = names(rv$raw_data$metadata),
          value = vapply(rv$raw_data$metadata, function(v) {
            paste(as.character(v), collapse = ", ")
          }, character(1)),
          stringsAsFactors = FALSE
        )
      } else {
        df <- as.data.frame(rv$raw_data$sample_info)
      }
      DT::datatable(df, options = list(pageLength = 10, dom = "tip"))
    })
  })
}
