# Peaks module
mod_peaks_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      title = "Peak detection",
      shiny::sliderInput(ns("snr"), "SNR threshold",
                         min = 1, max = 20, value = 5, step = 0.5),
      shiny::sliderInput(ns("prom"), "Min prominence (fraction of max)",
                         min = 0.001, max = 0.2, value = 0.01, step = 0.001),
      shiny::sliderInput(ns("dist"), "Min distance (nm)",
                         min = 0.1, max = 3, value = 0.5, step = 0.1),
      shiny::selectInput(ns("elements"), "Optional reference annotations",
                         choices = c("Ca", "Na", "K", "Mg", "Fe",
                                     "Zn", "Cu", "P", "C", "H", "O",
                                     "N", "Mn", "Sr", "Ba", "Pb", "Cd",
                                     "Cr", "Al", "Si", "Li", "Ti", "Cl"),
                         multiple = TRUE,
                         selected = character()),
      shiny::actionButton(ns("detect"), "Detect peaks",
                          class = "btn-primary w-100"),
      shiny::helpText("A dataset uses its first spectrum. The table and download identify that sample; markers show exactly the detected peaks."),
      shiny::helpText("Line matches are wavelength candidates. The confidence column is a distance score, not a probability of elemental identity; check candidate counts and wavelength medium."),
      shiny::helpText("Annotations require your configured atomic reference. Leave the selection empty to inspect spectra and detect peaks without one."),
      shiny::uiOutput(ns("reference_state")),
      shiny::uiOutput(ns("state"))
    ),
    bslib::card(
      bslib::card_header("Spectrum with peaks"),
      plotly::plotlyOutput(ns("plot"), height = "400px")
    ),
    bslib::card(
      bslib::card_header("Peaks and candidate line matches"),
      DT::DTOutput(ns("table"))
    )
  )
}

mod_peaks_server <- function(id, rv) {
  shiny::moduleServer(id, function(input, output, session) {
    status <- shiny::reactiveVal("Ready. Detect peaks for the current settings.")
    output$state <- shiny::renderUI(shiny::tagList(
      .ls_app_status(.ls_app_teaching_note(rv$processed_data %||% rv$raw_data)),
      .ls_app_result_status(status(), rv$peaks,
        "Ready. Detect peaks for the current data and settings.")))
    shiny::observeEvent(list(input$snr, input$prom, input$dist, input$elements,
                             rv$raw_data, rv$processed_data), {
      rv$peaks <- NULL
      status("Ready. Detect peaks for the current data and settings.")
    }, ignoreInit = TRUE, priority = 20)
    shiny::observeEvent(input$detect, {
      spec <- rv$processed_data %||% rv$raw_data
      shiny::req(spec)
      if (inherits(spec, "libs_dataset")) spec <- spec$spectra[[1]]
      rv$peaks <- NULL
      result <- .ls_app_attempt({
        pk <- libscanR::ls_find_peaks(spec,
                                      snr_threshold = input$snr,
                                      min_prominence = input$prom,
                                      min_distance_nm = input$dist)
        pk$sample_id <- rep(spec$metadata[["sample_id"]] %||% "spectrum", nrow(pk))
        pk
      }, status)
      if (result$ok) {
        pk <- result$value
        annotation_error <- NULL
        if (nrow(pk) > 0 && length(input$elements) > 0) {
          annotated <- .ls_app_attempt(
            libscanR::ls_identify_peaks(pk, elements = input$elements))
          if (annotated$ok) pk <- annotated$value else {
            annotation_error <- paste("Annotation unavailable:",
              conditionMessage(annotated$error))
          }
        }
        rv$peaks <- pk
        status(paste(c(sprintf("Complete. %d peaks detected.", nrow(pk)),
          annotation_error), collapse = " "))
      }
    })

    annotated_plot <- shiny::reactive({
      spec <- rv$processed_data %||% rv$raw_data
      shiny::req(spec)
      if (inherits(spec, "libs_dataset")) spec <- spec$spectra[[1]]
      elements <- if (length(input$elements)) input$elements else NULL
      tryCatch(list(plot = libscanR::ls_plot_spectrum(spec, show_elements = elements),
        error = NULL), error = function(e) {
          list(plot = libscanR::ls_plot_spectrum(spec), error = conditionMessage(e))
        })
    })
    output$reference_state <- shiny::renderUI({
      error <- annotated_plot()$error
      if (is.null(error)) return(NULL)
      .ls_app_status(paste("Reference annotation unavailable.", error,
        "The raw spectrum and peak detection remain available."))
    })
    output$plot <- plotly::renderPlotly({
      p <- annotated_plot()$plot
      if (!is.null(rv$peaks) && nrow(rv$peaks)) {
        p <- p + ggplot2::geom_point(data = rv$peaks,
          ggplot2::aes(x = .data$wavelength_nm, y = .data$intensity),
          colour = "#A23B72", size = 1.5)
      }
      plotly::ggplotly(p)
    })

    output$table <- DT::renderDT({
      shiny::req(rv$peaks)
      df <- rv$peaks
      df[] <- lapply(df, function(col) {
        if (is.numeric(col)) round(col, 4) else col
      })
      DT::datatable(df, options = list(pageLength = 15, dom = "tip"))
    })
  })
}
