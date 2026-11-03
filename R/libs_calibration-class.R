#' Create a LIBS Calibration Model
#'
#' Constructs a `libs_calibration` S3 object holding a fitted calibration
#' model plus the underlying training data and figures of merit.
#'
#' @param element Character. Element symbol (e.g. "Ca", "Fe").
#' @param wavelength_nm Numeric. Emission line wavelength used.
#' @param concentrations Numeric vector. Known concentrations of standards.
#' @param intensities Numeric vector. Measured peak intensities or areas
#'   (or ratios for `internal_std`). Same length as `concentrations`.
#' @param model Fitted model object (`lm` with one plain numeric predictor and
#'   an intercept, or `mvr` for PLS). Transformed terms and offsets are rejected
#'   by univariate prediction.
#' @param method Character. One of `"univariate"`, `"internal_std"`, `"pls"`,
#'   `"cf_libs"`. Default `"univariate"`.
#' @param lod Numeric. Limit of detection (3-sigma). Default `NULL`.
#' @param loq Numeric. Limit of quantification (10-sigma). Default `NULL`.
#' @param r_squared Numeric. Coefficient of determination. Default `NULL`.
#' @param unit Character. Concentration unit, e.g. `"ppm"`, `"wt_pct"`,
#'   `"mg_kg"`. Default `"ppm"`.
#'
#' @param feature_contract Optional fitted wavelength/preprocessing and extraction
#'   contract, normally populated by [ls_calibrate()].
#' @param response_model Optional response-on-concentration regression used to
#'   estimate univariate detection limits.
#' @param lod_basis Character description of the limit estimate, or `NULL`.
#' @param training_rmse Numeric training prediction error, or `NULL`. This is not
#'   a detection limit or a held-out estimate.
#'
#' @return A `libs_calibration` S3 object.
#'
#' @examples
#' conc <- c(100, 500, 1000, 2500, 5000)
#' ints <- conc * 0.12 + stats::rnorm(5, 0, 5)
#' m <- stats::lm(conc ~ ints)
#' cal <- ls_calibration("Ca", 393.37, conc, ints, model = m,
#'                       r_squared = summary(m)$r.squared)
#' print(cal)
#'
#' @export
ls_calibration <- function(element, wavelength_nm, concentrations, intensities,
                           model, method = "univariate", lod = NULL, loq = NULL,
                           r_squared = NULL, unit = "ppm",
                           feature_contract = NULL, response_model = NULL,
                           lod_basis = NULL, training_rmse = NULL) {
  method <- match.arg(method, c("univariate", "internal_std", "pls", "cf_libs"))
  if (!is.character(element) || length(element) != 1L || is.na(element) || !nzchar(trimws(element))) {
    cli::cli_abort("{.arg element} must be a single character string.")
  }
  if (!is.numeric(wavelength_nm) || is.complex(wavelength_nm) || length(wavelength_nm) != 1L ||
      !is.null(dim(wavelength_nm)) || !is.finite(wavelength_nm) || wavelength_nm <= 0) {
    cli::cli_abort("{.arg wavelength_nm} must be a single numeric value.")
  }
  if (length(concentrations) != length(intensities)) {
    cli::cli_abort("{.arg concentrations} and {.arg intensities} must have equal length.")
  }

  .check_numeric_vector(concentrations, "concentrations")
  .check_numeric_vector(intensities, "intensities")
  if (!is.character(unit) || length(unit) != 1L || is.na(unit) || !nzchar(trimws(unit))) {
    cli::cli_abort("{.arg unit} must be a non-empty character string.")
  }
  for (name in c("lod", "loq", "r_squared", "training_rmse")) {
    value <- get(name)
    if (!is.null(value) && (!is.numeric(value) || is.complex(value) ||
        length(value) != 1L || !is.null(dim(value)) || is.infinite(value) ||
        (!is.na(value) && name != "r_squared" && value < 0))) {
      cli::cli_abort("{.arg {name}} must be a finite scalar or NA (unavailable).")
    }
  }
  structure(
    list(
      element = element,
      wavelength_nm = wavelength_nm,
      concentrations = as.numeric(concentrations),
      intensities = as.numeric(intensities),
      model = model,
      method = method,
      lod = lod,
      loq = loq,
      r_squared = r_squared,
      unit = unit,
      n_standards = length(concentrations),
      feature_contract = feature_contract,
      response_model = response_model,
      lod_basis = lod_basis,
      training_rmse = training_rmse
    ),
    class = "libs_calibration"
  )
}

#' Print a LIBS Calibration
#' @param x A `libs_calibration` object.
#' @param ... Unused.
#' @return Invisibly `x`.
#' @export
print.libs_calibration <- function(x, ...) {
  cli::cli_inform(c(
    "{.cls libs_calibration}",
    "*" = "Element: {.val {x$element}}",
    "*" = "Line: {.val {round(x$wavelength_nm, 3)}} nm",
    "*" = "Method: {.val {x$method}}",
    "*" = "Unit: {.val {x$unit}}",
    "*" = "Standards: {x$n_standards}",
    "*" = if (!is.null(x$r_squared)) "R-squared: {.val {round(x$r_squared, 4)}}" else "R-squared: (not set)",
    "*" = if (!is.null(x$lod)) "LOD: {.val {signif(x$lod, 3)}} {x$unit}" else "LOD: (not set)",
    "*" = if (!is.null(x$loq)) "LOQ: {.val {signif(x$loq, 3)}} {x$unit}" else "LOQ: (not set)"
  ))
  invisible(x)
}

#' Summary of a LIBS Calibration
#' @param object A `libs_calibration` object.
#' @param ... Unused.
#' @return Invisibly a list of key figures of merit.
#' @export
summary.libs_calibration <- function(object, ...) {
  print(object)
  if (!is.null(object$model) && inherits(object$model, "lm")) {
    coefs <- stats::coef(object$model)
    cli::cli_inform(c(
      "i" = "Model: concentration = {round(coefs[1], 4)} + {round(coefs[2], 6)} * intensity"
    ))
  }
  invisible(list(
    element = object$element,
    wavelength_nm = object$wavelength_nm,
    method = object$method,
    r_squared = object$r_squared,
    lod = object$lod,
    loq = object$loq,
    n_standards = object$n_standards
  ))
}

#' Predict Concentrations from a Calibration Model
#'
#' @param object A `libs_calibration` object.
#' @param newdata A finite numeric vector of already integrated responses (ratios
#'   for internal-standard calibration), or a matrix with the fitted PLS columns
#'   in their trained order. This low-level method cannot verify wavelength labels;
#'   use [ls_quantify()] for spectra with checked feature identity.
#' @param ... Unused.
#' @return Numeric vector of predicted concentrations.
#' @export
predict.libs_calibration <- function(object, newdata, ...) {
  if (!inherits(object, "libs_calibration")) cli::cli_abort("{.arg object} must be a {.cls libs_calibration}.")
  if (is.null(object[["model"]])) cli::cli_abort("Calibration has no fitted model.")
  method <- object[["method"]]
  if (method %in% c("univariate", "internal_std")) {
    .check_numeric_vector(newdata, "newdata")
    .calibration_predictor(object[["model"]])
    co <- stats::coef(object[["model"]])
    pred <- unname(co[["(Intercept)"]] + co[names(co) != "(Intercept)"] * newdata)
  } else if (identical(object[["method"]], "pls")) {
    .require_pkg("pls", "Needed to predict from a PLS calibration.")
    if (is.numeric(newdata) && is.null(dim(newdata))) newdata <- matrix(newdata, nrow = 1L)
    expected <- dim(object[["model"]]$coefficients)[1L]
    if (!is.matrix(newdata) || !is.numeric(newdata) || is.complex(newdata) ||
        any(!is.finite(newdata)) || nrow(newdata) < 1L || ncol(newdata) != expected) {
      cli::cli_abort("PLS newdata must be a finite numeric matrix with {expected} fitted feature columns.")
    }
    pred <- as.numeric(stats::predict(object[["model"]], newdata = newdata,
                                      ncomp = object[["model"]]$ncomp))
  } else cli::cli_abort("Unsupported calibration method: {.val {method}}")
  if (any(!is.finite(pred))) cli::cli_abort("Calibration predictions are non-finite.")
  as.numeric(pred)
}

.calibration_predictor <- function(model) {
  if (!inherits(model, "lm") || inherits(model, "glm")) {
    cli::cli_abort("Univariate calibration requires an lm linear model, not a generalized linear model.")
  }
  terms <- stats::delete.response(stats::terms(model))
  labels <- attr(terms, "term.labels")
  variables <- all.vars(terms)
  co <- stats::coef(model)
  if (length(variables) != 1L || length(labels) != 1L ||
      !identical(labels, variables) || !is.null(attr(terms, "offset")) ||
      length(co) != 2L || !identical(names(co), c("(Intercept)", variables)) ||
      any(!is.finite(co))) {
    cli::cli_abort("Univariate calibration requires one plain numeric predictor and an intercept; transformed terms and offsets are not supported.")
  }
  variables
}

#' Test whether an object is a libs_calibration
#' @param x Object to test.
#' @return Logical scalar.
#' @export
is_libs_calibration <- function(x) {
  inherits(x, "libs_calibration")
}
