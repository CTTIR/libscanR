# Quantification and figures of merit
# -----------------------------------------------------------------------------

#' Quantify Element Concentration
#'
#' Applies a calibration model using its saved wavelength axis, preprocessing and
#' extraction contract. Legacy models without this contract must be refitted.
#' Unavailable detection-limit flags are `NA`, not FALSE.
#'
#' @param calibration A [ls_calibration()] object.
#' @param x A [ls_spectrum()] or [ls_dataset()] object.
#' @param window_nm Optional numeric integration window. `NULL` reuses the fitted
#'   window; a different supplied value is rejected.
#'
#' @return A [tibble::tibble()] with columns `sample_id`, `element`,
#'   `concentration`, `unit`, `below_lod`, `below_loq`.
#'
#' @examples
#' ds <- ls_example_data("calibration")
#' conc <- ds$sample_info$concentration
#' cal <- ls_calibrate(ds, "Ca", 393.37, conc, verbose = FALSE)
#' ls_quantify(cal, ds)
#' @export
ls_quantify <- function(calibration, x, window_nm = NULL) {
  contract <- .require_calibration_contract(calibration, window_nm)
  single_id <- NULL
  if (inherits(x, "libs_spectrum")) {
    .validate_spectrum(x)
    single_id <- as.character(.meta_get(x$metadata, "sample_id", "unknown"))
    x <- ls_dataset(list(x))
  } else if (!inherits(x, "libs_dataset")) {
    cli::cli_abort("{.arg x} must be a {.cls libs_spectrum} or {.cls libs_dataset}.")
  }
  .assert_spectral_contract(contract, x)
  features <- .calibration_features(contract, x)
  preds <- predict(calibration, features)
  below <- function(limit) {
    if (is.null(limit) || length(limit) != 1L || !is.finite(limit)) return(rep(NA, length(preds)))
    preds < limit
  }
  tibble::tibble(
    sample_id = if (is.null(single_id)) x$sample_info$sample_id else single_id,
    element = calibration$element, concentration = preds, unit = calibration$unit,
    below_lod = below(calibration$lod), below_loq = below(calibration$loq)
  )
}

.require_calibration_contract <- function(calibration, window_nm = NULL) {
  if (!inherits(calibration, "libs_calibration")) {
    cli::cli_abort("{.arg calibration} must be a {.cls libs_calibration} object.")
  }
  contract <- calibration[["feature_contract"]]
  if (!is.list(contract) || anyDuplicated(names(contract)) ||
      !identical(contract[["schema_version"]], 1L) ||
      !all(c("wavelength", "processing", "method", "line_nm", "window_nm") %in% names(contract))) {
    cli::cli_abort("This calibration lacks a supported feature contract; refit it with {.fn ls_calibrate} before quantifying spectra.")
  }
  if (!identical(contract[["method"]], calibration[["method"]]) ||
      !identical(as.numeric(contract[["line_nm"]]), as.numeric(calibration[["wavelength_nm"]]))) {
    cli::cli_abort("Calibration metadata differs from its fitted feature contract; refit the calibration.")
  }
  if (!is.null(window_nm)) {
    .check_number(window_nm, "window_nm", min = .Machine$double.eps)
    if (window_nm != contract[["window_nm"]]) {
      cli::cli_abort("{.arg window_nm} differs from the fitted integration window; refit for a different window.")
    }
  }
  contract
}

#' Limit of Detection (3-sigma)
#'
#' Calculates LOD using the 3-sigma criterion.
#'
#' @param calibration A [ls_calibration()] object.
#' @param blank Optional [ls_spectrum()] of a blank sample. If `NULL` (the
#'   default), LOD is recomputed from the residual standard error of the
#'   response-on-concentration calibration model. A supplied blank must contain
#'   at least two replicate shots on the fitted axis with the same preprocessing;
#'   its standard deviation is computed from the same integrated response (or
#'   internal-standard ratio) for each shot, not variation across wavelengths.
#' @param window_nm Optional window; `NULL` uses the fitted window. A different
#'   value is rejected.
#'
#' @return Estimated numeric LOD in the calibration's concentration unit; `NA`
#'   for PLS. This 3-sigma estimate requires independent confirmation near the
#'   detection limit and is not an instrument qualification.
#'
#' @examples
#' ds <- ls_example_data("calibration")
#' conc <- ds$sample_info$concentration
#' cal <- ls_calibrate(ds, "Ca", 393.37, conc, verbose = FALSE)
#' ls_lod(cal)
#' @export
ls_lod <- function(calibration, blank = NULL, window_nm = NULL) {
  contract <- .require_calibration_contract(calibration, window_nm)
  if (identical(calibration$method, "pls")) {
    if (!is.null(blank)) cli::cli_abort("A blank alone does not establish a multivariate PLS detection limit.")
    return(NA_real_)
  }
  response <- calibration[["response_model"]]
  if (!inherits(response, "lm")) cli::cli_abort("Calibration lacks a response-scale fit; refit before estimating detection limits.")
  slope <- stats::coef(response)[["concentration"]]
  if (length(slope) != 1L || !is.finite(slope) || slope == 0) cli::cli_abort("Calibration response sensitivity must be finite and nonzero.")
  if (is.null(blank)) {
    sigma <- sqrt(sum(stats::residuals(response)^2) / stats::df.residual(response))
  } else {
    .validate_spectrum(blank)
    if (blank$n_shots < 2L) cli::cli_abort("Blank-based limits require at least two replicate shots; channel-to-channel variability is not replicate noise.")
    .assert_spectral_contract(contract, ls_dataset(list(blank)))
    samples <- lapply(seq_len(blank$n_shots), function(i) {
      ls_spectrum(blank$wavelength, blank$intensity[i, , drop = FALSE],
                  metadata = list(sample_id = paste0("blank_", i),
                                  processing = contract[["processing"]]))
    })
    sigma <- stats::sd(.calibration_features(contract, ls_dataset(samples)))
  }
  limit <- 3 * sigma / abs(slope)
  if (!is.finite(limit)) cli::cli_abort("Detection-limit estimate is non-finite.")
  limit
}

#' Limit of Quantification (10-sigma)
#'
#' Calculates LOQ using the 10-sigma criterion.
#'
#' @param calibration A [ls_calibration()] object.
#' @param blank Optional [ls_spectrum()] of a blank sample.
#' @param window_nm Optional window; `NULL` uses the fitted window.
#'
#' @return Numeric LOQ in the calibration's concentration unit.
#'
#' @examples
#' ds <- ls_example_data("calibration")
#' conc <- ds$sample_info$concentration
#' cal <- ls_calibrate(ds, "Ca", 393.37, conc, verbose = FALSE)
#' ls_loq(cal)
#' @export
ls_loq <- function(calibration, blank = NULL, window_nm = NULL) {
  lod <- ls_lod(calibration, blank, window_nm)
  lod * 10 / 3
}
