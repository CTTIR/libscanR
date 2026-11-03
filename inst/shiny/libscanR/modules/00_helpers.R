# Shared application state and admission helpers.
`%||%` <- function(a, b) if (is.null(a)) b else a

.ls_app_clear_results <- function(rv) {
  rv$peaks <- NULL
  rv$calibrations <- list()
  rv$pca_result <- NULL
  rv$plsda_result <- NULL
  rv$cluster_result <- NULL
}

.ls_app_admit <- function(rv, data) {
  # Explicit admission also resets results when the new bytes equal the old data.
  rv$processed_data <- NULL
  .ls_app_clear_results(rv)
  rv$raw_data <- data
  rv$import_error <- NULL
}

.ls_app_attempt <- function(code, status = function(text) NULL) {
  tryCatch(withCallingHandlers({
    list(ok = TRUE, value = force(code))
  }, warning = function(w) {
    shiny::showNotification(conditionMessage(w), type = "warning", duration = NULL)
  }), error = function(e) {
    if (inherits(e, "shiny.silent.error")) stop(e)
    message <- e$message %||% conditionMessage(e)
    status(paste("Failed:", message))
    shiny::showNotification(message, type = "error", duration = NULL)
    list(ok = FALSE, error = e)
  })
}

.ls_app_status <- function(text) {
  shiny::div(class = "libscanR-status", role = "status", `aria-live` = "polite", text)
}

.ls_app_result_status <- function(text, result, ready) {
  # Admission/reset may clear a result even when its source bytes are identical.
  if (is.null(result) && startsWith(text, "Complete.")) text <- ready
  .ls_app_status(text)
}

.ls_app_dataset <- function(rv) {
  data <- rv$processed_data %||% rv$raw_data
  if (!inherits(data, "libs_dataset")) {
    cli::cli_abort("Load a dataset with multiple spectra for this analysis.")
  }
  data
}

.ls_app_download <- function(code) {
  result <- .ls_app_attempt(code)
  if (!result$ok) shiny::req(FALSE)
  invisible(NULL)
}

.ls_app_upload <- function(files, format) {
  format <- match.arg(format, c("auto", "generic", "sciaps", "aurora"))
  if (!is.data.frame(files) || !nrow(files) ||
      !all(c("name", "datapath") %in% names(files))) {
    cli::cli_abort("Choose at least one spectrum file.")
  }
  names <- as.character(files$name)
  if (anyNA(names) || any(!nzchar(names)) ||
      any(grepl("[/\\\\]", names)) || any(grepl("[[:cntrl:]]", names)) ||
      any(!tolower(tools::file_ext(names)) %in% c("csv", "tsv", "txt")) ||
      anyDuplicated(tolower(names))) {
    cli::cli_abort("Upload distinct CSV, TSV or TXT filenames without paths.")
  }
  staging <- tempfile("libscanR-upload-")
  if (!dir.create(staging)) cli::cli_abort("Cannot prepare uploaded spectra.")
  on.exit(unlink(staging, recursive = TRUE), add = TRUE)
  specs <- lapply(seq_len(nrow(files)), function(i) {
    tryCatch({
      path <- file.path(staging, names[i])
      if (!file.copy(files$datapath[i], path, overwrite = FALSE)) {
        cli::cli_abort("Cannot read the uploaded file.")
      }
      spec <- switch(format,
        auto = libscanR::ls_read_auto(path, verbose = FALSE),
        generic = libscanR::ls_read_spectrum(path, verbose = FALSE),
        sciaps = libscanR::ls_read_sciaps(path, verbose = FALSE),
        aurora = libscanR::ls_read_aurora(path, verbose = FALSE))
      # The upload name identifies the submitted file, not a retained local path.
      spec$metadata$source_file <- names[i]
      spec$metadata$source_location <- "browser upload"
      spec
    }, error = function(e) {
      cli::cli_abort("Import of {.file {names[i]}} failed: {conditionMessage(e)}",
                     parent = e)
    })
  })
  if (length(specs) == 1L) specs[[1]] else libscanR::ls_dataset(specs)
}

.ls_app_mean_table <- function(data) {
  ids <- as.character(data$sample_info$sample_id)
  if ("wavelength_nm" %in% ids) {
    cli::cli_abort("Sample ID {.val wavelength_nm} conflicts with the CSV axis column; use the complete ZIP download.")
  }
  df <- data.frame(wavelength_nm = data$wavelength)
  for (i in seq_along(ids)) df[[ids[i]]] <- data$intensity_matrix[i, ]
  df
}

.ls_app_archive <- function(data, file) {
  staging <- tempfile("libscanR-export-")
  if (!dir.create(staging)) cli::cli_abort("Cannot prepare the ZIP download.")
  on.exit(unlink(staging, recursive = TRUE), add = TRUE)
  if (inherits(data, "libs_dataset")) {
    libscanR::ls_export_spectra(data, staging)
  } else {
    libscanR::ls_write_csv(data, file.path(staging, "spectrum.csv"))
  }
  files <- list.files(staging, full.names = TRUE)
  result <- utils::zip(file, files = files, flags = "-j")
  if (!identical(as.integer(result), 0L) || !file.exists(file)) {
    cli::cli_abort("The ZIP download could not be created; check that the system zip command is available.")
  }
}

# Teaching provenance is explicit and is never inferred from element labels.
.ls_app_teaching_origin <- function(data) {
  spectra <- if (inherits(data, "libs_dataset")) data$spectra else list(data)
  teaching <- vapply(spectra, function(spec) {
    if (!inherits(spec, "libs_spectrum")) return(FALSE)
    source <- spec$metadata[["line_source"]]
    is.list(source) && identical(source[["kind"]], "explicit_synthetic_peaks")
  }, logical(1))
  if (!any(teaching)) return(NULL)
  if (all(teaching)) "explicit_synthetic_peaks" else "includes_explicit_synthetic_peaks"
}

.ls_app_teaching_note <- function(data) {
  if (is.null(.ls_app_teaching_origin(data))) return(NULL)
  paste("Fictional teaching spectra are present. Component labels and concentrations",
    "are invented for demonstrations, not atomic reference data or experimental measurements.")
}
