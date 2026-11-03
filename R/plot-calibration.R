# Calibration plots
# -----------------------------------------------------------------------------

#' Plot a Calibration Curve
#'
#' @param calibration A [ls_calibration()] object. PLS shows fitted training
#'   concentrations against known concentrations, not a one-feature curve.
#' @param show_lod Logical. Show LOD as a horizontal dashed line. Default `TRUE`.
#' @param show_loq Logical. Show LOQ as a horizontal dashed line. Default `TRUE`.
#' @param show_prediction_interval Logical. Show 95% prediction band.
#'   Default `TRUE`. For univariate/internal-standard fits this is the fitted
#'   model's interval for a new observation, not a confidence band for its mean.
#'   PLS plots do not supply a prediction interval.
#'
#' @return A ggplot2 object.
#'
#' @examples
#' ds <- ls_example_data("calibration")
#' conc <- ds$sample_info$concentration
#' cal <- ls_calibrate(ds, "Ca", 393.37, conc, verbose = FALSE)
#' ls_plot_calibration(cal)
#' @export
ls_plot_calibration <- function(calibration, show_lod = TRUE,
                                show_loq = TRUE,
                                show_prediction_interval = TRUE) {
  if (!inherits(calibration, "libs_calibration")) {
    cli::cli_abort("{.arg calibration} must be a {.cls libs_calibration}.")
  }
  .check_flag(show_lod, "show_lod")
  .check_flag(show_loq, "show_loq")
  .check_flag(show_prediction_interval, "show_prediction_interval")
  if (calibration$method == "pls") {
    ncomp <- calibration$model$ncomp
    fitted <- as.numeric(stats::fitted(calibration$model)[, , ncomp])
    df <- data.frame(known = calibration$concentrations, fitted = fitted)
    return(ggplot2::ggplot(df, ggplot2::aes(x = .data$known, y = .data$fitted)) +
      ggplot2::geom_point(size = 2.5, colour = "#2E86AB", alpha = 0.8) +
      ggplot2::geom_abline(intercept = 0, slope = 1, linetype = "dashed") +
      ggplot2::labs(x = paste0("Known concentration (", calibration$unit, ")"),
        y = paste0("Training fitted concentration (", calibration$unit, ")"),
        title = paste0("PLS calibration: ", calibration$element),
        subtitle = "Training predictions; detection limits and prediction intervals are unavailable") +
      theme_libs())
  }
  if (!calibration$method %in% c("univariate", "internal_std")) {
    cli::cli_abort("Calibration plots require a univariate, internal-standard or PLS fit.")
  }
  predictor <- .calibration_predictor(calibration$model)
  df <- data.frame(intensity = calibration$intensities,
                    concentration = calibration$concentrations)
  grid <- seq(min(df$intensity), max(df$intensity), length.out = 100L)
  newdata <- stats::setNames(data.frame(grid), predictor)
  band <- as.data.frame(stats::predict(calibration$model, newdata = newdata,
                                        interval = "prediction", level = .95))
  band$intensity <- grid
  response_label <- if (calibration$method == "internal_std") {
    "Internal-standard area ratio"
  } else "Integrated peak response (a.u. nm)"
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$intensity,
                                       y = .data$concentration))
  if (show_prediction_interval) {
    p <- p + ggplot2::geom_ribbon(data = band,
      ggplot2::aes(x = .data$intensity, ymin = .data$lwr, ymax = .data$upr),
      inherit.aes = FALSE, fill = "#A23B72", alpha = .15)
  }
  p <- p + ggplot2::geom_line(data = band,
    ggplot2::aes(x = .data$intensity, y = .data$fit),
    inherit.aes = FALSE, colour = "#A23B72") +
    ggplot2::geom_point(size = 2.5, colour = "#2E86AB", alpha = .8) +
    ggplot2::labs(x = response_label,
      y = paste0("Concentration (", calibration$unit, ")"),
      title = paste0(calibration$element, " @ ", round(calibration$wavelength_nm, 2), " nm"),
      subtitle = sprintf("Training R^2 = %.4f | Estimated LOD = %.3g | LOQ = %.3g %s",
                         calibration$r_squared %||% NA_real_,
                         calibration$lod %||% NA_real_,
                         calibration$loq %||% NA_real_, calibration$unit)) +
    theme_libs()
  available <- function(value) is.numeric(value) && length(value) == 1L && is.finite(value)
  if (show_lod && available(calibration$lod)) {
    p <- p + ggplot2::geom_hline(yintercept = calibration$lod,
                                linetype = "dashed", colour = "orange") +
      ggplot2::annotate("text", x = min(df$intensity), y = calibration$lod,
        label = "LOD", vjust = -.5, hjust = 0, colour = "orange", size = 3)
  }
  if (show_loq && available(calibration$loq)) {
    p <- p + ggplot2::geom_hline(yintercept = calibration$loq,
                                linetype = "dashed", colour = "red") +
      ggplot2::annotate("text", x = min(df$intensity), y = calibration$loq,
        label = "LOQ", vjust = -.5, hjust = 0, colour = "red", size = 3)
  }
  p
}

#' Plot Calibration Residuals
#'
#' Standard regression diagnostic: residuals vs fitted.
#'
#' @param calibration A [ls_calibration()] object.
#' @return A ggplot2 object.
#'
#' @examples
#' ds <- ls_example_data("calibration")
#' conc <- ds$sample_info$concentration
#' cal <- ls_calibrate(ds, "Ca", 393.37, conc, verbose = FALSE)
#' ls_plot_residuals(cal)
#' @export
ls_plot_residuals <- function(calibration) {
  if (!inherits(calibration, "libs_calibration")) {
    cli::cli_abort("{.arg calibration} must be a {.cls libs_calibration}.")
  }
  if (calibration$method %in% c("univariate", "internal_std")) {
    fitted <- stats::fitted(calibration$model)
    resid <- stats::residuals(calibration$model)
  } else if (calibration$method == "pls") {
    ncomp <- calibration$model$ncomp
    fitted <- stats::fitted(calibration$model)[, , ncomp]
    resid <- calibration$concentrations - fitted
  } else {
    cli::cli_abort("Unsupported calibration method: {.val {calibration$method}}")
  }
  df <- data.frame(fitted_value = fitted, residual = resid)
  ggplot2::ggplot(df, ggplot2::aes(x = .data$fitted_value,
                                   y = .data$residual)) +
    ggplot2::geom_point(colour = "#2E86AB", size = 2, alpha = 0.8) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed",
                        colour = "grey30") +
    ggplot2::labs(x = "Fitted", y = "Residual",
                  title = paste0("Residuals: ", calibration$element)) +
    theme_libs()
}
