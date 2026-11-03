# Preprocessing module
mod_preprocess_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      title = "Preprocessing",
      shiny::selectInput(ns("baseline_method"), "Baseline",
                         choices = c("snip", "als", "rolling_ball",
                                     "linear", "polynomial", "none"),
                         selected = "snip"),
      shiny::numericInput(ns("baseline_iter"), "Baseline iterations",
                          value = 100, min = 10, max = 500),
      shiny::hr(),
      shiny::selectInput(ns("norm_method"), "Normalization",
                         choices = c("none", "total", "max", "snv", "area"),
                         selected = "none"),
      shiny::hr(),
      shiny::selectInput(ns("smooth_method"), "Smoothing",
                         choices = c("none", "savgol", "moving_avg",
                                     "gaussian", "median"),
                         selected = "none"),
      shiny::numericInput(ns("smooth_window"), "Window size",
                          value = 11, min = 3, max = 51),
      shiny::hr(),
      shiny::numericInput(ns("crop_min"), "Crop min (nm, 0 = off)", value = 0),
      shiny::numericInput(ns("crop_max"), "Crop max (nm, 0 = off)", value = 0),
      shiny::actionButton(ns("apply"), "Apply",
                          class = "btn-primary w-100 mt-2"),
      shiny::actionButton(ns("reset"), "Reset",
                          class = "btn-outline-secondary w-100 mt-2"),
      shiny::helpText("Apply replaces the processed data. Until then, plots and downloads use the last successful result. Reset restores raw data."),
      shiny::uiOutput(ns("state"))
    ),
    bslib::card(
      bslib::card_header("Raw vs Processed"),
      plotly::plotlyOutput(ns("compare"), height = "500px")
    )
  )
}

mod_preprocess_server <- function(id, rv) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    status <- shiny::reactiveVal("Ready. Choose settings and apply.")
    output$state <- shiny::renderUI(.ls_app_result_status(status(),
      rv$processed_data, "Ready. Plots and downloads use raw data."))
    shiny::observeEvent(rv$raw_data, {
      status("Ready. New raw data loaded.")
    }, ignoreInit = TRUE, ignoreNULL = FALSE)

    shiny::observeEvent(input$apply, {
      shiny::req(rv$raw_data)
      result <- .ls_app_attempt({
        proc <- rv$raw_data
        if (input$baseline_method != "none") {
          proc <- libscanR::ls_baseline(proc,
                                        method = input$baseline_method,
                                        iterations = input$baseline_iter)
        }
        if (input$norm_method != "none") {
          proc <- libscanR::ls_normalize(proc, method = input$norm_method)
        }
        if (input$smooth_method != "none") {
          win <- input$smooth_window
          proc <- libscanR::ls_smooth(proc,
                                      method = input$smooth_method,
                                      window = win)
        }
        if (input$crop_min > 0 || input$crop_max > 0) {
          mn <- if (input$crop_min > 0) input$crop_min else NULL
          mx <- if (input$crop_max > 0) input$crop_max else NULL
          proc <- libscanR::ls_crop(proc, min_nm = mn, max_nm = mx)
        }
        proc
      }, function(text) status(paste(text, "The previous data are retained.")))
      if (result$ok) {
        .ls_app_clear_results(rv)
        rv$processed_data <- result$value
        status("Complete. Plots and downloads use the applied result.")
      }
    })

    shiny::observeEvent(input$reset, {
      rv$processed_data <- NULL
      .ls_app_clear_results(rv)
      status("Reset. Plots and downloads use raw data.")
    })

    output$compare <- plotly::renderPlotly({
      shiny::req(rv$raw_data)
      # Single-spectrum comparison. If dataset, show first spectrum.
      raw_spec <- if (inherits(rv$raw_data, "libs_spectrum")) rv$raw_data
      else rv$raw_data$spectra[[1]]
      raw_df <- data.frame(
        wavelength_nm = raw_spec$wavelength,
        intensity = libscanR:::.mean_intensity(raw_spec),
        kind = "raw"
      )
      dfs <- list(raw_df)
      if (!is.null(rv$processed_data)) {
        proc_spec <- if (inherits(rv$processed_data, "libs_spectrum")) {
          rv$processed_data
        } else rv$processed_data$spectra[[1]]
        proc_df <- data.frame(
          wavelength_nm = proc_spec$wavelength,
          intensity = libscanR:::.mean_intensity(proc_spec),
          kind = "processed"
        )
        dfs[[2]] <- proc_df
      }
      df <- do.call(rbind, dfs)
      p <- ggplot2::ggplot(df,
                           ggplot2::aes(x = .data$wavelength_nm,
                                        y = .data$intensity,
                                        colour = .data$kind)) +
        ggplot2::geom_line(alpha = 0.8) +
        libscanR::theme_libs() +
        ggplot2::labs(x = "Wavelength (nm)", y = "Intensity (a.u.)",
                      colour = NULL)
      plotly::ggplotly(p)
    })
  })
}
