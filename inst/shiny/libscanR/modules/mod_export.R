# Export module
mod_export_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      title = "Export",
      shiny::downloadButton(ns("dl_archive"), "Complete spectra (ZIP)",
                            class = "btn-primary w-100 mb-2"),
      shiny::downloadButton(ns("dl_spectra"), "Spectrum / dataset means (CSV)",
                            class = "btn-primary w-100 mb-2"),
      shiny::downloadButton(ns("dl_peaks"), "Peaks (CSV)",
                            class = "btn-primary w-100 mb-2"),
      shiny::downloadButton(ns("dl_calibration"), "Calibration (CSV)",
                            class = "btn-primary w-100 mb-2"),
      shiny::downloadButton(ns("dl_info"), "Sample info (CSV)",
                            class = "btn-primary w-100 mb-2"),
      shiny::helpText("ZIP preserves every shot and per-spectrum metadata. Dataset CSV contains only mean intensities; a single-spectrum CSV retains its shots and metadata."),
      shiny::helpText("ZIP creation needs an external zip command on PATH, or configured through R_ZIPCMD, including on Windows."),
      shiny::helpText("Calibration CSV summarizes fitted figures of merit; it is not a serialized prediction model. Peak and calibration CSVs mark explicit fictional teaching inputs in data_origin.")
    ),
    bslib::card(
      bslib::card_header("Export summary"),
      shiny::uiOutput(ns("summary"))
    )
  )
}

mod_export_server <- function(id, rv) {
  shiny::moduleServer(id, function(input, output, session) {
    output$summary <- shiny::renderUI({
      data <- rv$processed_data %||% rv$raw_data
      if (is.null(data)) {
        return(shiny::div(class = "libscanR-status",
                          "Nothing to export. Load data in the Import tab first."))
      }
      txt <- if (inherits(data, "libs_dataset")) {
        sprintf("Ready: %d spectra, %d channels.",
                data$n_spectra, data$n_channels)
      } else {
        sprintf("Ready: spectrum with %d channels, %d shots.",
                data$n_channels, data$n_shots)
      }
      source <- if (is.null(rv$processed_data)) "raw" else "last applied processed"
      availability <- paste(
        if (is.null(rv$peaks)) "Detect peaks before downloading a peak table." else "Current peak table available.",
        if (!length(rv$calibrations)) "Build a calibration before downloading its summary." else "Calibration summary available.")
      .ls_app_status(paste(c(txt, "Downloads use", source, "data.", availability,
        .ls_app_teaching_note(data)), collapse = " "))
    })

    output$dl_archive <- shiny::downloadHandler(
      filename = function() "libscanR_spectra.zip",
      content = function(file) {
        data <- rv$processed_data %||% rv$raw_data
        shiny::req(data)
        .ls_app_download(.ls_app_archive(data, file))
      }
    )

    output$dl_spectra <- shiny::downloadHandler(
      filename = function() "libscanR_spectra.csv",
      content = function(file) {
        data <- rv$processed_data %||% rv$raw_data
        shiny::req(data)
        .ls_app_download(if (inherits(data, "libs_spectrum")) {
          libscanR::ls_write_csv(data, file)
        } else {
          utils::write.csv(.ls_app_mean_table(data), file, row.names = FALSE)
        })
      }
    )
    output$dl_peaks <- shiny::downloadHandler(
      filename = function() "libscanR_peaks.csv",
      content = function(file) {
        .ls_app_download({
          if (is.null(rv$peaks)) cli::cli_abort("Detect peaks for the current data and settings before downloading.")
          peaks <- rv$peaks
          data <- rv$processed_data %||% rv$raw_data
          source <- if (inherits(data, "libs_dataset")) data$spectra[[1]] else data
          origin <- .ls_app_teaching_origin(source)
          if (!is.null(origin)) peaks$data_origin <- rep(origin, nrow(peaks))
          utils::write.csv(peaks, file, row.names = FALSE)
        })
      }
    )
    output$dl_calibration <- shiny::downloadHandler(
      filename = function() "libscanR_calibration.csv",
      content = function(file) {
        cals <- rv$calibrations
        .ls_app_download({
          if (!length(cals)) cli::cli_abort("Build a calibration for the current data before downloading.")
          rows <- lapply(cals, function(c) {
          data.frame(
            element = c$element,
            wavelength_nm = c$wavelength_nm,
            method = c$method,
            r_squared = c$r_squared %||% NA,
            lod = c$lod %||% NA,
            loq = c$loq %||% NA,
            unit = c$unit,
            n_standards = c$n_standards,
            lod_basis = c$lod_basis %||% NA_character_,
            training_rmse = c$training_rmse %||% NA_real_
          )
          })
          df <- do.call(rbind, rows)
          data <- rv$processed_data %||% rv$raw_data
          origin <- .ls_app_teaching_origin(data)
          if (!is.null(origin)) df$data_origin <- rep(origin, nrow(df))
          utils::write.csv(df, file, row.names = FALSE)
        })
      }
    )
    output$dl_info <- shiny::downloadHandler(
      filename = function() "libscanR_sample_info.csv",
      content = function(file) {
        data <- rv$processed_data %||% rv$raw_data
        shiny::req(inherits(data, "libs_dataset"))
        .ls_app_download(utils::write.csv(data$sample_info, file, row.names = FALSE))
      }
    )
  })
}
