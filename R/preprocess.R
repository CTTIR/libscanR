# Preprocessing functions
# -----------------------------------------------------------------------------

#' Baseline Correction
#'
#' Removes continuum/baseline drift from LIBS spectra. Supported methods:
#' `"snip"` (Statistics-sensitive Non-linear Iterative Peak-clipping,
#' Morhac/Ryan), `"als"` (Asymmetric Least Squares smoothing, Eilers &
#' Boelens), `"rolling_ball"` (morphological), `"linear"` (two-endpoint
#' interpolation), or `"polynomial"` (low-order polynomial fit of
#' baseline-only regions).
#'
#' @param x A [ls_spectrum()] or [ls_dataset()] object.
#' @param method Character. One of `"snip"`, `"als"`, `"rolling_ball"`,
#'   `"linear"`, `"polynomial"`. Default `"snip"`.
#' @param iterations Integer. Iterations for iterative methods (SNIP, ALS).
#'   Default 100.
#' @param order Integer. Polynomial order for `"polynomial"`. Default 3.
#' @param lambda Numeric. Smoothness parameter for ALS. Default `1e5`.
#' @param p Numeric. Asymmetry parameter for ALS (0 < p < 1). Default 0.01.
#' @param radius Integer. Rolling-ball radius in channels. Default 50.
#' @param ... Reserved for future use.
#'
#' @return Same class as input with baseline-corrected intensities; the
#'   estimated baseline is stored in the `baseline` element for inspection.
#'
#' @examples
#' spec <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1)
#' corr <- ls_baseline(spec, method = "snip")
#' is.null(corr$baseline)
#'
#' @export
ls_baseline <- function(x, method = "snip", iterations = 100,
                        order = 3, lambda = 1e5, p = 0.01,
                        radius = 50, ...) {
  method <- match.arg(method, c("snip", "als", "rolling_ball",
                                "linear", "polynomial"))
  if (inherits(x, "libs_dataset")) {
    .validate_dataset(x)
    new_spectra <- lapply(x$spectra, ls_baseline, method = method,
                          iterations = iterations, order = order,
                          lambda = lambda, p = p, radius = radius)
    return(ls_dataset(new_spectra, sample_info = x$sample_info))
  }
  .validate_spectrum(x)

  .check_number(iterations, "iterations", min = 1, integer = TRUE)
  .check_number(order, "order", min = 1, integer = TRUE)
  .check_number(lambda, "lambda", min = .Machine$double.eps)
  .check_number(p, "p", min = .Machine$double.eps, max = 1 - .Machine$double.eps)
  .check_number(radius, "radius", min = 1, integer = TRUE)
  new_int <- x$intensity
  baselines <- matrix(0, nrow = nrow(new_int), ncol = ncol(new_int))
  for (i in seq_len(nrow(new_int))) {
    y <- new_int[i, ]
    bg <- switch(method,
                 snip = .baseline_snip(y, iterations),
                 als = .baseline_als(y, lambda, p, iterations),
                 rolling_ball = .baseline_rolling(y, radius),
                 linear = .baseline_linear(y, x$wavelength),
                 polynomial = .baseline_poly(x$wavelength, y, order))
    new_int[i, ] <- y - bg
    baselines[i, ] <- bg
  }
  baseline_vec <- colMeans(baselines)
  ls_spectrum(
    wavelength = x$wavelength,
    intensity = new_int,
    metadata = .record_processing(x$metadata, "baseline", list(
      method = method, iterations = iterations, order = order,
      lambda = lambda, p = p, radius = radius)),
    baseline = baseline_vec
  )
}

#' Normalize Spectra
#'
#' Normalizes intensity values. Methods:
#' * `"total"` — divide each shot by total intensity
#' * `"max"` — divide by per-shot maximum
#' * `"snv"` — Standard Normal Variate: `(x - mean) / sd`
#' * `"internal_std"` — divide by intensity at a reference line
#' * `"area"` — divide by integrated (trapezoidal) area
#'
#' @param x A [ls_spectrum()] or [ls_dataset()] object.
#' @param method Character. Normalization method. Default `"total"`.
#' @param ref_wavelength Numeric. Required for `method = "internal_std"`.
#' @param ref_window Numeric. Window width (nm) around `ref_wavelength`.
#'   Default 1.
#'
#' @return Same class as input with normalized intensities. A zero or non-finite
#'   divisor is an error; a constant SNV shot becomes zero. Previous removed
#'   baselines are retained in `metadata$baseline_history` and cleared from
#'   `baseline`, because per-shot scaling changes their units.
#'
#' @examples
#' spec <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1)
#' spec_n <- ls_normalize(spec, method = "total")
#' sum(spec_n$intensity[1, ])  # ~1
#'
#' @export
ls_normalize <- function(x, method = "total", ref_wavelength = NULL,
                         ref_window = 1) {
  method <- match.arg(method, c("total", "max", "snv",
                                "internal_std", "area"))
  if (inherits(x, "libs_dataset")) {
    .validate_dataset(x)
    new_spectra <- lapply(x$spectra, ls_normalize, method = method,
                          ref_wavelength = ref_wavelength,
                          ref_window = ref_window)
    return(ls_dataset(new_spectra, sample_info = x$sample_info))
  }
  .validate_spectrum(x)

  if (method == "internal_std" && is.null(ref_wavelength)) {
    cli::cli_abort("{.arg ref_wavelength} is required for method 'internal_std'.")
  }

  if (method == "internal_std") {
    .check_number(ref_wavelength, "ref_wavelength", min = .Machine$double.eps)
    .check_number(ref_window, "ref_window", min = .Machine$double.eps)
  }
  new_int <- x$intensity
  for (i in seq_len(nrow(new_int))) {
    y <- new_int[i, ]
    denom <- switch(method,
                    total = sum(y, na.rm = TRUE),
                    max = max(y, na.rm = TRUE),
                    snv = NA,
                    internal_std = {
                      lo <- ref_wavelength - ref_window / 2
                      hi <- ref_wavelength + ref_window / 2
                      idx <- which(x$wavelength >= lo & x$wavelength <= hi)
                      if (length(idx) == 0) {
                        cli::cli_abort("No channels within {.val {ref_window}} nm of {.val {ref_wavelength}}.")
                      }
                      max(y[idx], na.rm = TRUE)
                    },
                    area = abs(.trapz(x$wavelength, y)))
    if (method == "snv") {
      m <- mean(y, na.rm = TRUE)
      s <- stats::sd(y, na.rm = TRUE)
      if (s == 0) s <- 1
      new_int[i, ] <- (y - m) / s
    } else {
      if (!is.finite(denom) || denom == 0) {
        cli::cli_abort("Cannot normalize shot {i}: the normalization denominator is zero or non-finite.")
      }
      new_int[i, ] <- y / denom
    }
  }

  meta <- .record_processing(x$metadata, "normalize", list(
    method = method, ref_wavelength = ref_wavelength, ref_window = ref_window))
  if (!is.null(x[["baseline"]])) {
    meta$baseline_history <- c(.meta_get(meta, "baseline_history", list()),
                              list(list(stage = "before normalization", values = x[["baseline"]])))
  }
  ls_spectrum(
    wavelength = x$wavelength,
    intensity = new_int,
    metadata = meta,
    baseline = NULL
  )
}

#' Smooth Spectra
#'
#' Applies spectral smoothing. Methods: `"savgol"` (Savitzky-Golay, needs
#' the `signal` package when available, otherwise uses local polynomial least
#' squares with an intercept), `"moving_avg"`, `"gaussian"`, `"median"`.
#'
#' @param x A [ls_spectrum()] or [ls_dataset()] object.
#' @param method Character. Default `"savgol"`.
#' @param window Integer. Window size in channels (odd preferred). Default 11.
#' @param poly_order Integer. Polynomial order for Savitzky-Golay. Default 3.
#'
#' @return Same class as input with smoothed intensities.
#'
#' @examples
#' spec <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1)
#' sm <- ls_smooth(spec, method = "moving_avg", window = 9)
#'
#' @export
ls_smooth <- function(x, method = "savgol", window = 11, poly_order = 3) {
  method <- match.arg(method, c("savgol", "moving_avg", "gaussian", "median"))
  if (inherits(x, "libs_dataset")) {
    .validate_dataset(x)
    new_spectra <- lapply(x$spectra, ls_smooth, method = method,
                          window = window, poly_order = poly_order)
    return(ls_dataset(new_spectra, sample_info = x$sample_info))
  }
  .validate_spectrum(x)
  .check_number(window, "window", min = 1, integer = TRUE)
  .check_number(poly_order, "poly_order", min = 0, integer = TRUE)
  if (window %% 2 == 0) window <- window + 1  # ensure odd
  if (window > x$n_channels) cli::cli_abort("Smoothing window exceeds the number of channels.")
  if (method == "savgol") {
    if (poly_order >= window) cli::cli_abort("poly_order must be smaller than the smoothing window.")
    spacing <- diff(x$wavelength)
    if (max(abs(spacing / mean(spacing) - 1)) > 1e-7) {
      cli::cli_abort("Savitzky-Golay smoothing requires an evenly spaced wavelength axis.")
    }
  }

  new_int <- x$intensity
  for (i in seq_len(nrow(new_int))) {
    y <- new_int[i, ]
    new_int[i, ] <- switch(method,
                           savgol = .smooth_savgol(y, window, poly_order),
                           moving_avg = .smooth_mavg(y, window),
                           gaussian = .smooth_gauss(y, window),
                           median = stats::runmed(y, k = window, endrule = "keep"))
  }

  ls_spectrum(
    wavelength = x$wavelength,
    intensity = new_int,
    metadata = .record_processing(x$metadata, "smooth", list(
      method = method, window = window, poly_order = poly_order)),
    baseline = x[["baseline"]]
  )
}

#' Crop Spectral Range
#'
#' Subsets a spectrum or dataset to a wavelength range.
#'
#' @param x A [ls_spectrum()] or [ls_dataset()] object.
#' @param min_nm Numeric. Minimum wavelength (nm). Default `NULL` = no lower bound.
#' @param max_nm Numeric. Maximum wavelength (nm). Default `NULL` = no upper bound.
#'
#' @return Same class as input, cropped.
#'
#' @examples
#' spec <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1)
#' ls_crop(spec, 380, 450)
#' @export
ls_crop <- function(x, min_nm = NULL, max_nm = NULL) {
  if (inherits(x, "libs_dataset")) {
    .validate_dataset(x)
    new_spectra <- lapply(x$spectra, ls_crop, min_nm = min_nm, max_nm = max_nm)
    return(ls_dataset(new_spectra, sample_info = x$sample_info))
  }
  .validate_spectrum(x)
  wl <- x$wavelength
  if (is.null(min_nm)) min_nm <- min(wl)
  if (is.null(max_nm)) max_nm <- max(wl)
  .check_number(min_nm, "min_nm", min = 0)
  .check_number(max_nm, "max_nm", min = min_nm)
  idx <- which(wl >= min_nm & wl <= max_nm)
  if (length(idx) == 0) {
    cli::cli_abort("No channels fall in [{min_nm}, {max_nm}] nm.")
  }
  ls_spectrum(
    wavelength = wl[idx],
    intensity = x$intensity[, idx, drop = FALSE],
    metadata = .record_processing(x$metadata, "crop", list(min_nm = min_nm, max_nm = max_nm)),
    baseline = if (is.null(x[["baseline"]])) NULL else x[["baseline"]][idx]
  )
}

#' Average Replicate Shots
#'
#' Averages shots within a [ls_spectrum()].
#'
#' @param x A [ls_spectrum()] object.
#' @param method Character. `"mean"` or `"median"`. Default `"mean"`.
#' @param trim Numeric. Fraction trimmed from each end for trimmed mean.
#'   Default 0.
#' @param remove_outliers Logical. Remove shots with deviation > 3 SD from
#'   the per-channel mean. Default `FALSE`.
#'
#' @return A `libs_spectrum` with a single averaged shot.
#'
#' @examples
#' spec <- ls_simulate_spectrum(line_data = ls_demo_peaks(), n_shots = 10, seed = 1)
#' ls_average_shots(spec, remove_outliers = TRUE)
#'
#' @export
ls_average_shots <- function(x, method = "mean", trim = 0,
                             remove_outliers = FALSE) {
  .validate_spectrum(x)
  method <- match.arg(method, c("mean", "median"))
  .check_number(trim, "trim", min = 0, max = 0.5)
  .check_flag(remove_outliers, "remove_outliers")
  mat <- x$intensity
  if (nrow(mat) == 1) return(x)

  keep <- rep(TRUE, nrow(mat))
  if (remove_outliers && nrow(mat) >= 4) {
    col_mean <- colMeans(mat)
    col_sd <- apply(mat, 2, stats::sd)
    col_sd[col_sd == 0] <- 1
    z_scores <- apply(mat, 1, function(y) mean(abs((y - col_mean) / col_sd), na.rm = TRUE))
    keep <- z_scores <= 3
    if (sum(keep) == 0) keep <- rep(TRUE, nrow(mat))
  }
  submat <- mat[keep, , drop = FALSE]
  avg <- if (method == "mean") {
    apply(submat, 2, mean, trim = trim, na.rm = TRUE)
  } else {
    apply(submat, 2, stats::median, na.rm = TRUE)
  }

  new_meta <- .record_processing(x$metadata, "average_shots", list(
    method = method, trim = trim, remove_outliers = remove_outliers))
  new_meta$averaged_shots <- sum(keep)
  new_meta$averaged_method <- method

  ls_spectrum(
    wavelength = x$wavelength,
    intensity = matrix(avg, nrow = 1),
    metadata = new_meta,
    baseline = x[["baseline"]]
  )
}

#' Gate Delay Optimization
#'
#' Analyzes SNR and signal-to-background ratios across spectra acquired at
#' different gate delays to recommend optimal timing for a target line.
#'
#' @param spectra List of [ls_spectrum()] objects. Each spectrum's metadata
#'   should contain `gate_delay_us`.
#' @param element Character. Target element symbol.
#' @param line_nm Numeric. Target emission line wavelength (nm).
#' @param window_nm Numeric. Window around the line. Default 1.
#'
#' @return A [tibble::tibble()] with columns `gate_delay_us`, `snr`, `sbr`,
#'   `peak_intensity`, with attribute `"recommended"` giving the row index
#'   of the highest SNR.
#'
#' @examples
#' specs <- lapply(c(0.5, 1, 2, 5, 10), function(g) {
#'   s <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = round(g * 10))
#'   s$metadata$gate_delay_us <- g
#'   s
#' })
#' ls_gate_optimize(specs, "Ca", 393.37)
#' @export
ls_gate_optimize <- function(spectra, element, line_nm, window_nm = 1) {
  if (!is.list(spectra) || length(spectra) == 0) {
    cli::cli_abort("{.arg spectra} must be a non-empty list.")
  }
  gd <- vapply(spectra, function(s) {
    as.numeric(.meta_get(s$metadata, "gate_delay_us", NA_real_))
  }, numeric(1))

  snr_vec <- numeric(length(spectra))
  sbr_vec <- numeric(length(spectra))
  peak_vec <- numeric(length(spectra))
  for (i in seq_along(spectra)) {
    s <- spectra[[i]]
    y <- .mean_intensity(s)
    lo <- line_nm - window_nm / 2
    hi <- line_nm + window_nm / 2
    idx <- which(s$wavelength >= lo & s$wavelength <= hi)
    if (length(idx) == 0) next
    peak <- max(y[idx], na.rm = TRUE)
    bg_idx <- c(which(s$wavelength >= lo - 2 * window_nm & s$wavelength < lo),
                which(s$wavelength > hi & s$wavelength <= hi + 2 * window_nm))
    bg <- if (length(bg_idx) > 0) stats::median(y[bg_idx], na.rm = TRUE) else 0
    noise <- if (length(bg_idx) > 0) stats::mad(y[bg_idx], na.rm = TRUE) else .estimate_noise(y)
    if (is.na(noise) || noise == 0) noise <- 1
    snr_vec[i] <- (peak - bg) / noise
    sbr_vec[i] <- if (bg <= 0) Inf else peak / bg
    peak_vec[i] <- peak
  }

  out <- tibble::tibble(
    gate_delay_us = gd,
    snr = snr_vec,
    sbr = sbr_vec,
    peak_intensity = peak_vec
  )
  recommended <- which.max(snr_vec)
  attr(out, "recommended") <- recommended
  attr(out, "element") <- element
  attr(out, "line_nm") <- line_nm
  out
}

# -----------------------------------------------------------------------------
# Internal baseline & smoothing kernels
# -----------------------------------------------------------------------------

#' @keywords internal
#' @noRd
.baseline_snip <- function(y, n_iter = 100) {
  # Morhac/Ryan SNIP
  y_log <- log(log(sqrt(abs(y) + 1) + 1) + 1)
  n <- length(y_log)
  for (m in seq_len(n_iter)) {
    previous <- y_log
    for (i in seq_len(n)) {
      lo <- max(1, i - m)
      hi <- min(n, i + m)
      y_log[i] <- min(previous[i], (previous[lo] + previous[hi]) / 2)
    }
  }
  bg <- (exp(exp(y_log) - 1) - 1)^2 - 1
  bg
}

#' @keywords internal
#' @noRd
.baseline_als <- function(y, lambda = 1e5, p = 0.01, n_iter = 10) {
  n <- length(y)
  if (n < 3L) return(y)
  rows <- seq_len(n - 2L)
  D <- Matrix::sparseMatrix(i = rep(rows, 3),
                            j = c(rows, rows + 1L, rows + 2L),
                            x = rep(c(1, -2, 1), each = n - 2L),
                            dims = c(n - 2L, n))
  penalty <- lambda * Matrix::crossprod(D)
  w <- rep(1, n)
  for (i in seq_len(n_iter)) {
    A <- Matrix::Diagonal(x = w) + penalty
    z <- as.numeric(Matrix::solve(A, w * y))
    next_w <- ifelse(y > z, p, 1 - p)
    if (identical(w, next_w)) break
    w <- next_w
  }
  z
}

#' @keywords internal
#' @noRd
.baseline_rolling <- function(y, radius = 50) {
  n <- length(y)
  bg <- numeric(n)
  radius <- min(radius, floor(n / 2))
  for (i in seq_len(n)) {
    lo <- max(1, i - radius)
    hi <- min(n, i + radius)
    bg[i] <- min(y[lo:hi], na.rm = TRUE)
  }
  k <- max(3, 2 * radius + 1)
  if (k %% 2 == 0) k <- k + 1
  k <- min(k, n - (n %% 2 == 0))
  bg <- stats::filter(bg, rep(1 / k, k), sides = 2)
  bg[is.na(bg)] <- y[is.na(bg)]
  as.numeric(bg)
}

#' @keywords internal
#' @noRd
.baseline_linear <- function(y, wl = seq_along(y)) {
  n <- length(y)
  if (n < 2) return(rep(y[1], n))
  y_start <- stats::median(y[seq_len(max(1, floor(n * 0.02)))])
  y_end <- stats::median(y[(n - max(0, floor(n * 0.02))):n])
  stats::approx(x = c(wl[1], wl[n]), y = c(y_start, y_end), xout = wl)$y
}

#' @keywords internal
#' @noRd
.baseline_poly <- function(wl, y, order = 3) {
  # Iteratively fit a polynomial to the lower envelope.
  keep <- rep(TRUE, length(y))
  pred <- rep(mean(y, na.rm = TRUE), length(y))
  order <- max(1, min(order, length(y) - 2))
  for (k in 1:5) {
    if (sum(keep) <= order + 1) break
    x_sub <- wl[keep]
    y_sub <- y[keep]
    fit <- stats::lm(y_sub ~ stats::poly(x_sub, degree = order, raw = TRUE))
    co <- stats::coef(fit)
    # Evaluate polynomial at all wl
    pred <- co[1]
    for (p in seq_len(order)) {
      pred <- pred + co[p + 1] * wl^p
    }
    pred <- as.numeric(pred)
    resid <- y - pred
    keep <- resid < stats::quantile(resid, 0.5, na.rm = TRUE)
  }
  pred
}

#' @keywords internal
#' @noRd
.smooth_savgol <- function(y, window, poly_order) {
  if (requireNamespace("signal", quietly = TRUE)) {
    return(as.numeric(signal::sgolayfilt(y, p = poly_order, n = window)))
  }
  .savgol_local(y, window, poly_order)
}

.savgol_local <- function(y, window, poly_order) {
  n <- length(y)
  half <- (window - 1L) / 2L
  vapply(seq_len(n), function(i) {
    lo <- max(1L, min(i - half, n - window + 1L))
    idx <- seq.int(lo, length.out = window)
    design <- outer(idx - i, 0:poly_order, `^`)
    as.numeric(stats::lm.fit(design, y[idx])$coefficients[1])
  }, numeric(1))
}

#' @keywords internal
#' @noRd
.smooth_mavg <- function(y, window) {
  k <- rep(1 / window, window)
  smooth <- stats::filter(y, k, sides = 2)
  smooth[is.na(smooth)] <- y[is.na(smooth)]
  as.numeric(smooth)
}

#' @keywords internal
#' @noRd
.smooth_gauss <- function(y, window) {
  half <- (window - 1) / 2
  sigma <- window / 6
  k_x <- seq(-half, half)
  k <- exp(-(k_x^2) / (2 * sigma^2))
  k <- k / sum(k)
  smooth <- stats::filter(y, k, sides = 2)
  smooth[is.na(smooth)] <- y[is.na(smooth)]
  as.numeric(smooth)
}


.record_processing <- function(metadata, operation, parameters) {
  history <- .meta_get(metadata, "processing", list())
  if (!is.list(history)) cli::cli_abort("metadata$processing must be a list of processing steps.")
  metadata$processing <- c(history,
                           list(list(operation = operation, parameters = parameters)))
  metadata
}
