# Calibration curve construction (univariate, internal std, PLS, CF-LIBS)
# -----------------------------------------------------------------------------

#' Build Calibration Curve
#'
#' Constructs a calibration model from standards with known concentrations.
#'
#' @param dataset A [ls_dataset()] containing standard spectra. Spectra
#'   order must correspond to `concentrations`.
#' @param element Character. Target element symbol.
#' @param line_nm Numeric. Emission line wavelength (nm).
#' @param concentrations Numeric vector of known concentrations, one per
#'   spectrum in `dataset`.
#' @param method Character. `"univariate"` (default), `"internal_std"`,
#'   `"pls"`, or `"cf_libs"`.
#' @param internal_std_nm Numeric. Internal standard line wavelength,
#'   required for `method = "internal_std"`.
#' @param window_nm Numeric. Peak integration window. Default 1.
#' @param pls_window_nm Numeric vector of length 2. Spectral window for PLS.
#'   Default `c(line_nm - 5, line_nm + 5)`.
#' @param n_components Integer. Number of PLS components. Default 5.
#' @param unit Character. Concentration unit. Default `"ppm"`.
#' @param verbose Logical. Default `TRUE`.
#'
#' @details Prediction preserves the fitted wavelength axis, ordered preprocessing,
#'   integration window and internal-standard ratio or PLS columns. Univariate
#'   predictions retain inverse concentration-on-response regression. Estimated
#'   3-sigma LOD and 10-sigma LOQ use the residual standard deviation of a separate
#'   response-on-concentration fit divided by its absolute slope. These estimates
#'   require independent verification near the limits; they are not validated
#'   instrument limits. PLS reports training RMSE separately and leaves LOD/LOQ
#'   unavailable (`NA`); residual prediction error alone is not a detection limit.
#'
#' @return A [ls_calibration()] object.
#'
#' @examples
#' ds <- ls_example_data("calibration")
#' conc <- ds$sample_info$concentration
#' cal <- ls_calibrate(ds, "Ca", 393.37, conc, verbose = FALSE)
#' print(cal)
#' @export
ls_calibrate <- function(dataset, element, line_nm, concentrations,
                         method = "univariate", internal_std_nm = NULL,
                         window_nm = 1,
                         pls_window_nm = NULL, n_components = 5,
                         unit = "ppm", verbose = TRUE) {
  .validate_dataset(dataset)
  .check_flag(verbose, "verbose")
  method <- match.arg(method, c("univariate", "internal_std", "pls", "cf_libs"))
  if (length(concentrations) != dataset$n_spectra) {
    cli::cli_abort("{.arg concentrations} length ({length(concentrations)}) must match number of spectra ({dataset$n_spectra}).")
  }
  .check_numeric_vector(concentrations, "concentrations", 3L)
  if (length(unique(concentrations)) < 2L) cli::cli_abort("Calibration requires distinct concentrations.")
  .check_number(line_nm, "line_nm", min = min(dataset$wavelength), max = max(dataset$wavelength))
  .check_number(window_nm, "window_nm", min = .Machine$double.eps)
  if (method == "cf_libs") cli::cli_abort("Use {.fn ls_saha_boltzmann} for CF-LIBS on a single spectrum.")

  contract <- .spectral_feature_contract(dataset)
  contract$method <- method
  contract$line_nm <- line_nm
  contract$window_nm <- window_nm
  contract$internal_std_nm <- NULL
  if (method == "internal_std") {
    if (is.null(internal_std_nm)) cli::cli_abort("{.arg internal_std_nm} is required for internal standard calibration.")
    .check_number(internal_std_nm, "internal_std_nm", min = min(dataset$wavelength), max = max(dataset$wavelength))
    contract$internal_std_nm <- internal_std_nm
  }
  if (method == "pls") {
    .require_pkg("pls", "Required for PLS calibration.")
    .check_number(n_components, "n_components", min = 1, integer = TRUE)
    if (is.null(pls_window_nm)) pls_window_nm <- c(line_nm - 5, line_nm + 5)
    .check_numeric_vector(pls_window_nm, "pls_window_nm", 2L)
    if (length(pls_window_nm) != 2L || pls_window_nm[1L] >= pls_window_nm[2L]) {
      cli::cli_abort("{.arg pls_window_nm} must contain two increasing bounds.")
    }
    idx <- which(dataset$wavelength >= pls_window_nm[1L] & dataset$wavelength <= pls_window_nm[2L])
    if (!length(idx)) cli::cli_abort("The PLS window contains no measured channels.")
    contract$pls_indices <- idx
    X <- .calibration_features(contract, dataset)
    rank <- qr(scale(X, center = TRUE, scale = FALSE))$rank
    n_components <- min(n_components, nrow(X) - 1L, ncol(X), rank)
    if (n_components < 1L) cli::cli_abort("PLS calibration requires varying spectral features.")
    model_df <- data.frame(Y = as.numeric(concentrations))
    model_df$X <- X
    fit <- pls::plsr(Y ~ X, ncomp = n_components, data = model_df, validation = "none")
    pred <- as.numeric(stats::predict(fit, ncomp = n_components))
    if (any(!is.finite(pred))) cli::cli_abort("PLS calibration is numerically degenerate; reduce components or revise the standards.")
    r2 <- .r_squared(concentrations, pred)
    if (verbose) cli::cli_inform(c("v" = "PLS calibration fit: ncomp = {n_components}, R2 = {round(r2, 4)}"))
    return(ls_calibration(element, line_nm, concentrations, rowMeans(X), fit,
                          method = method, lod = NA_real_, loq = NA_real_,
                          r_squared = r2, unit = unit, feature_contract = contract,
                          lod_basis = "unavailable_for_pls",
                          training_rmse = sqrt(mean((concentrations - pred)^2))))
  }

  intensities <- .calibration_features(contract, dataset)
  if (length(unique(intensities)) < 2L) cli::cli_abort("Calibration requires varying integrated responses.")
  df <- data.frame(concentration = as.numeric(concentrations), intensity = intensities)
  # Retain inverse prediction behavior; estimate limits in response units.
  fit <- stats::lm(concentration ~ intensity, data = df)
  response_fit <- stats::lm(intensity ~ concentration, data = df)
  slope <- stats::coef(response_fit)[["concentration"]]
  if (!is.finite(slope) || slope == 0) cli::cli_abort("Calibration response sensitivity must be finite and nonzero.")
  sigma <- sqrt(sum(stats::residuals(response_fit)^2) / stats::df.residual(response_fit))
  lod <- 3 * sigma / abs(slope)
  loq <- 10 * sigma / abs(slope)
  pred <- as.numeric(stats::predict(fit))
  r2 <- .r_squared(concentrations, pred)
  if (!all(is.finite(c(lod, loq, pred)))) cli::cli_abort("Calibration fit is numerically non-finite.")
  if (verbose) cli::cli_inform(c("v" = "{method} calibration for {element}: R2 = {round(r2, 4)}, estimated LOD = {signif(lod, 3)} {unit}, LOQ = {signif(loq, 3)} {unit}"))
  ls_calibration(element, line_nm, concentrations, intensities, fit,
                  method = method, lod = lod, loq = loq, r_squared = r2, unit = unit,
                  feature_contract = contract, response_model = response_fit,
                  lod_basis = "response_residual_3sigma",
                  training_rmse = sqrt(mean((concentrations - pred)^2)))
}

.calibration_features <- function(contract, dataset) {
  if (identical(contract[["method"]], "pls")) {
    idx <- contract[["pls_indices"]]
    if (!is.numeric(idx) || !length(idx) || anyNA(idx) ||
        any(idx != trunc(idx)) || any(idx < 1L | idx > dataset$n_channels) || anyDuplicated(idx)) {
      cli::cli_abort("Invalid saved PLS feature selection; refit the calibration.")
    }
    return(dataset$intensity_matrix[, idx, drop = FALSE])
  }
  values <- vapply(dataset$spectra, function(s) {
    area <- ls_peak_area(s, contract[["line_nm"]], contract[["window_nm"]])
    if (identical(contract[["method"]], "internal_std")) {
      reference <- ls_peak_area(s, contract[["internal_std_nm"]], contract[["window_nm"]])
      if (!is.finite(reference) || reference <= 0) {
        cli::cli_abort("Internal-standard integrated response must be positive and finite for every spectrum.")
      }
      area <- area / reference
    }
    area
  }, numeric(1))
  if (any(!is.finite(values))) cli::cli_abort("Integrated calibration responses must be finite.")
  unname(values)
}

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

#' @keywords internal
#' @noRd
.r_squared <- function(obs, pred) {
  ss_res <- sum((obs - pred)^2, na.rm = TRUE)
  ss_tot <- sum((obs - mean(obs, na.rm = TRUE))^2, na.rm = TRUE)
  if (ss_tot == 0) return(NA_real_)
  1 - ss_res / ss_tot
}
