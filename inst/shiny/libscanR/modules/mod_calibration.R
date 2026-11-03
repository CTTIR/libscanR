# Calibration module
mod_calibration_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      title = "Calibration",
      shiny::selectInput(ns("element"), "Element",
                         choices = c("Ca", "Na", "K", "Mg", "Fe", "Zn",
                                     "Cu", "Pb", "Cd", "Cr"),
                         selected = "Ca"),
      shiny::numericInput(ns("line_nm"), "Emission line (nm)",
                          value = 393.37, step = 0.01),
      shiny::selectInput(ns("method"), "Method",
                         choices = c("univariate", "internal_std", "pls"),
                         selected = "univariate"),
      shiny::numericInput(ns("internal_std"), "Internal std line (nm)",
                          value = 589.00, step = 0.01),
      shiny::numericInput(ns("window"), "Integration window (nm)",
                          value = 1, step = 0.1),
      shiny::textInput(ns("conc_col"), "Concentration column in sample_info",
                       value = "concentration"),
      shiny::actionButton(ns("build"), "Build calibration",
                          class = "btn-primary w-100"),
      shiny::helpText("Use a dataset with known concentrations in sample_info. Changed settings require a new fit for the selected element."),
      shiny::helpText("PLS uses measured channels within 5 nm of the selected line. The integration-window control applies to univariate and internal-standard fits."),
      shiny::helpText("Missing detection or quantification limits mean unavailable, not zero. A PLS training error is separate from a detection limit."),
      shiny::uiOutput(ns("state"))
    ),
    bslib::card(
      bslib::card_header("Calibration curve"),
      shiny::plotOutput(ns("curve"), height = "400px")
    ),
    bslib::card(
      bslib::card_header("Figures of merit"),
      shiny::verbatimTextOutput(ns("stats"))
    )
  )
}

mod_calibration_server <- function(id, rv) {
  shiny::moduleServer(id, function(input, output, session) {
    status <- shiny::reactiveVal("Ready. Build a calibration for the current data.")
    output$state <- shiny::renderUI(shiny::tagList(
      .ls_app_status(.ls_app_teaching_note(rv$processed_data %||% rv$raw_data)),
      .ls_app_result_status(status(), rv$calibrations[[input$element %||% ""]],
        "Ready. Build a calibration for the current data and settings.")))
    shiny::observeEvent(list(input$element, input$line_nm, input$method,
                             input$internal_std, input$window, input$conc_col,
                             rv$raw_data, rv$processed_data), {
      if (!is.null(input$element)) rv$calibrations[[input$element]] <- NULL
      status("Ready. Build a calibration for the current data and settings.")
    }, ignoreInit = TRUE, priority = 20)
    shiny::observeEvent(input$build, {
      shiny::req(input$element)
      rv$calibrations[[input$element]] <- NULL
      result <- .ls_app_attempt({
        ds <- .ls_app_dataset(rv)
        if (!(input$conc_col %in% names(ds$sample_info))) {
          cli::cli_abort("Concentration column {.val {input$conc_col}} was not found in sample_info.")
        }
        concs <- ds$sample_info[[input$conc_col]]
        libscanR::ls_calibrate(ds, input$element, input$line_nm,
                               concentrations = concs,
                               method = input$method,
                               internal_std_nm = input$internal_std,
                               window_nm = input$window,
                               verbose = FALSE)
      }, status)
      if (result$ok) {
        rv$calibrations[[input$element]] <- result$value
        status("Complete. Calibration fitted to the current standards.")
      }
    })

    output$curve <- shiny::renderPlot({
      cal <- rv$calibrations[[input$element]]
      shiny::req(cal)
      plot <- libscanR::ls_plot_calibration(cal)
      plot + ggplot2::labs(subtitle = paste(strwrap(plot$labels$subtitle,
        width = 40), collapse = "\n"))
    }, alt = function() {
      cal <- rv$calibrations[[input$element %||% ""]]
      if (is.null(cal)) return("No current calibration fit.")
      paste(c(.ls_app_teaching_note(rv$processed_data %||% rv$raw_data),
        sprintf("Calibration fit for %s using %d standards; method %s. Numerical figures of merit follow the plot.",
          cal$element, cal$n_standards, cal$method)), collapse = " ")
    })

    output$stats <- shiny::renderPrint({
      cal <- rv$calibrations[[input$element]]
      shiny::req(cal)
      teaching <- .ls_app_teaching_note(rv$processed_data %||% rv$raw_data)
      if (!is.null(teaching)) cat(paste(strwrap(teaching, width = 65), collapse = "\n"), "\n\n")
      figure <- function(value) {
        if (is.null(value) || length(value) != 1L || is.na(value)) return("Unavailable")
        format(signif(value, 5), trim = TRUE)
      }
      cat(sprintf(paste0(
        "Element: %s\nMethod: %s\nStandards: %d\nR-squared: %s\n",
        "LOD (%s): %s\nLOQ (%s): %s\nLOD basis: %s\nTraining RMSE (%s): %s"),
        cal$element, cal$method, cal$n_standards, figure(cal$r_squared),
        cal$unit, figure(cal$lod), cal$unit, figure(cal$loq),
        gsub("_", " ", cal$lod_basis %||% "unavailable"),
        cal$unit, figure(cal$training_rmse)))
    })
  })
}
