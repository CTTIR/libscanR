# Shared fitted-feature identity: channel labels and ordered preprocessing.
.canonical_processing <- function(history) {
  if (!is.list(history) || is.data.frame(history)) {
    cli::cli_abort("metadata$processing must be an ordered list of processing steps.")
  }
  canonical <- function(x) {
    if (is.numeric(x) && !is.complex(x)) {
      storage.mode(x) <- "double"
      return(x)
    }
    if (is.list(x)) return(lapply(x, canonical))
    x
  }
  lapply(history, function(step) {
    if (!is.list(step) || !identical(sort(names(step)), c("operation", "parameters")) ||
        !is.character(step[["operation"]]) || length(step[["operation"]]) != 1L ||
        is.na(step[["operation"]]) || !nzchar(step[["operation"]]) ||
        !is.list(step[["parameters"]])) {
      cli::cli_abort("Invalid processing step; rebuild the processing history before fitting or predicting.")
    }
    .check_metadata(step[["parameters"]])
    list(operation = step[["operation"]], parameters = canonical(step[["parameters"]]))
  })
}

.spectral_feature_contract <- function(dataset) {
  .validate_dataset(dataset)
  histories <- lapply(dataset$spectra, function(s) {
    .canonical_processing(.meta_get(s$metadata, "processing", list()))
  })
  if (!all(vapply(histories, identical, logical(1), histories[[1L]]))) {
    cli::cli_abort("All fitted or predicted spectra must have the same ordered preprocessing history.")
  }
  list(schema_version = 1L, wavelength = as.numeric(dataset$wavelength),
       processing = histories[[1L]])
}

.assert_spectral_contract <- function(contract, dataset) {
  if (!is.list(contract) || anyDuplicated(names(contract)) ||
      !identical(contract[["schema_version"]], 1L) ||
      !all(c("wavelength", "processing") %in% names(contract))) {
    cli::cli_abort("This model lacks a supported feature contract; refit it with the current package before predicting spectra.")
  }
  .check_wavelength(contract[["wavelength"]])
  .canonical_processing(contract[["processing"]])
  current <- .spectral_feature_contract(dataset)
  if (!.same_axis(contract[["wavelength"]], current$wavelength) ||
      !identical(contract[["processing"]], current$processing)) {
    cli::cli_abort("Prediction wavelength axis or preprocessing differs from the fitted feature contract; align the data or refit.")
  }
  invisible(TRUE)
}

.check_numeric_vector <- function(x, name, min_length = 1L) {
  if (!is.numeric(x) || is.complex(x) || !is.null(dim(x)) ||
      length(x) < min_length || any(!is.finite(x))) {
    cli::cli_abort("{.arg {name}} must be a finite numeric vector with at least {min_length} values.")
  }
  invisible(TRUE)
}
