# Peak detection, identification, and area calculation
# -----------------------------------------------------------------------------

#' Find Emission Peaks
#'
#' Detects peaks in a LIBS spectrum using local maxima detection with
#' prominence and signal-to-noise filtering.
#'
#' @param x A [ls_spectrum()] object.
#' @param snr_threshold Numeric. Minimum signal-to-noise ratio. Default 3.
#' @param min_prominence Numeric. Minimum peak prominence as a fraction of
#'   maximum intensity (0-1). Default 0.01.
#' @param min_distance_nm Numeric. Minimum distance between peaks (nm).
#'   Default 0.5.
#'
#' @return A [tibble::tibble()] with columns `wavelength_nm`, `intensity`,
#'   `snr`, `prominence`, `fwhm_nm`, `area`, sorted by intensity descending.
#'
#' @examples
#' spec <- ls_simulate_spectrum(elements = c(Ca = 5000, Na = 1000), seed = 1)
#' peaks <- ls_find_peaks(spec, snr_threshold = 5)
#' head(peaks)
#'
#' @export
ls_find_peaks <- function(x, snr_threshold = 3, min_prominence = 0.01,
                          min_distance_nm = 0.5) {
  .validate_spectrum(x)
  .check_number(snr_threshold, "snr_threshold", min = 0)
  .check_number(min_prominence, "min_prominence", min = 0, max = 1)
  .check_number(min_distance_nm, "min_distance_nm", min = 0)
  wl <- x$wavelength
  y <- .mean_intensity(x)
  n <- length(y)

  noise <- .estimate_noise(y)
  if (is.na(noise) || noise == 0) noise <- 1
  ymax <- max(y, na.rm = TRUE)
  prom_thresh <- min_prominence * ymax

  # Local maxima: strictly greater than neighbors
  is_peak <- rep(FALSE, n)
  for (i in if (n >= 3L) seq.int(2L, n - 1L) else integer()) {
    if (y[i] > y[i - 1] && y[i] > y[i + 1]) is_peak[i] <- TRUE
  }
  idx <- which(is_peak)
  if (length(idx) == 0) {
    return(tibble::tibble(wavelength_nm = numeric(0),
                          intensity = numeric(0),
                          snr = numeric(0),
                          prominence = numeric(0),
                          fwhm_nm = numeric(0),
                          area = numeric(0)))
  }

  prominences <- vapply(idx, function(i) .peak_prominence(y, i), numeric(1))
  snrs <- (y[idx] - stats::median(y)) / noise
  keep <- prominences >= prom_thresh & snrs >= snr_threshold
  idx <- idx[keep]
  prominences <- prominences[keep]
  snrs <- snrs[keep]

  if (length(idx) == 0) {
    return(tibble::tibble(wavelength_nm = numeric(0),
                          intensity = numeric(0),
                          snr = numeric(0),
                          prominence = numeric(0),
                          fwhm_nm = numeric(0),
                          area = numeric(0)))
  }

  # Enforce minimum distance
  ord <- order(y[idx], decreasing = TRUE)
  keep2 <- rep(TRUE, length(idx))
  for (i in seq_along(ord)) {
    if (!keep2[ord[i]]) next
    too_close <- abs(wl[idx] - wl[idx[ord[i]]]) < min_distance_nm &
      seq_along(idx) != ord[i]
    keep2[too_close] <- FALSE
  }
  idx <- idx[keep2]
  prominences <- prominences[keep2]
  snrs <- snrs[keep2]

  fwhms <- vapply(idx, function(i) .peak_fwhm(wl, y, i), numeric(1))
  areas <- vapply(seq_along(idx), function(k) {
    i <- idx[k]
    width <- if (is.na(fwhms[k]) || fwhms[k] == 0) min_distance_nm else fwhms[k] * 1.5
    .peak_area_local(wl, y, wl[i], width)
  }, numeric(1))

  out <- tibble::tibble(
    wavelength_nm = wl[idx],
    intensity = y[idx],
    snr = snrs,
    prominence = prominences,
    fwhm_nm = fwhms,
    area = areas
  )
  out[order(out$intensity, decreasing = TRUE), ]
}

#' Identify Peaks Against the NIST Line Database
#'
#' Matches detected peaks to known atomic emission lines. Each peak is
#' assigned its best-scoring candidate from the curated NIST database.
#'
#' @param peaks A tibble from [ls_find_peaks()].
#' @param elements Character vector. Restrict search. Default `NULL` = all.
#' @param tolerance_nm Numeric. Maximum wavelength deviation. Default 0.2.
#' @param ionization Integer vector of ionization states. Default `c(1L, 2L)`.
#'
#' @return A tibble with all peak columns plus: `element`, `ionization`,
#'   `nist_wavelength_nm`, `nist_aki`, `deviation_nm`, `confidence` (0-1).
#'
#' @examples
#' spec <- ls_simulate_spectrum(elements = c(Ca = 5000, Na = 1000), seed = 1)
#' pk <- ls_find_peaks(spec, snr_threshold = 5)
#' id <- ls_identify_peaks(pk, elements = c("Ca", "Na"))
#' head(id)
#' @export
ls_identify_peaks <- function(peaks, elements = NULL, tolerance_nm = 0.2,
                              ionization = c(1L, 2L)) {
  .check_number(tolerance_nm, "tolerance_nm", min = .Machine$double.eps)
  if (!inherits(peaks, "data.frame")) {
    cli::cli_abort("{.arg peaks} must be a data.frame/tibble from {.fn ls_find_peaks}.")
  }
  required <- c("wavelength_nm", "intensity")
  missing_cols <- setdiff(required, names(peaks))
  if (length(missing_cols) > 0) {
    cli::cli_abort("{.arg peaks} is missing columns: {.val {missing_cols}}")
  }
  if (!is.numeric(peaks$wavelength_nm) || !is.numeric(peaks$intensity) ||
      any(!is.finite(peaks$wavelength_nm)) || any(!is.finite(peaks$intensity))) {
    cli::cli_abort("Peak wavelengths and intensities must be finite numeric values.")
  }

  db <- ls_element_db(elements = elements, ionization = ionization)
  if (nrow(db) == 0) {
    cli::cli_warn("No lines match the filter criteria.")
    out <- peaks
    out$element <- rep(NA_character_, nrow(out))
    out$ionization <- rep(NA_integer_, nrow(out))
    out$nist_wavelength_nm <- rep(NA_real_, nrow(out))
    out$nist_aki <- rep(NA_real_, nrow(out))
    out$deviation_nm <- rep(NA_real_, nrow(out))
    out$confidence <- rep(NA_real_, nrow(out))
    return(tibble::as_tibble(out))
  }

  n <- nrow(peaks)
  matched_element <- rep(NA_character_, n)
  matched_ion <- rep(NA_integer_, n)
  matched_wl <- rep(NA_real_, n)
  matched_aki <- rep(NA_real_, n)
  matched_dev <- rep(NA_real_, n)
  conf <- rep(NA_real_, n)

  max_aki <- max(db$aki, na.rm = TRUE)
  for (i in seq_len(n)) {
    dev <- peaks$wavelength_nm[i] - db$wavelength_nm
    within <- abs(dev) <= tolerance_nm
    if (!any(within)) next
    cand <- db[within, ]
    devs <- dev[within]
    # Score: weight by (1 - |dev|/tol) * (aki / max_aki)
    score <- (1 - abs(devs) / tolerance_nm) * (cand$aki / max_aki)
    best <- which.max(score)
    matched_element[i] <- cand$element[best]
    matched_ion[i] <- cand$ionization[best]
    matched_wl[i] <- cand$wavelength_nm[best]
    matched_aki[i] <- cand$aki[best]
    matched_dev[i] <- devs[best]
    conf[i] <- score[best]
  }

  out <- peaks
  out$element <- matched_element
  out$ionization <- matched_ion
  out$nist_wavelength_nm <- matched_wl
  out$nist_aki <- matched_aki
  out$deviation_nm <- matched_dev
  out$confidence <- conf
  tibble::as_tibble(out)
}

#' Calculate Peak Area
#'
#' Integrates peak area at a given emission line, with a local baseline
#' subtracted (linear interpolation between window edges).
#'
#' @param x A [ls_spectrum()] object.
#' @param center_nm Numeric. Peak center wavelength (nm).
#' @param window_nm Numeric. Integration window width. Default 1.
#'   To support coarsely sampled input, the effective window is at least five
#'   median channel spacings, with up to five nearest channels used at edges.
#'   This does not resolve overlapping lines; inspect instrument resolution
#'   and the integration region before interpreting an area as an element.
#' @param method Character. `"trapezoidal"` or `"gaussian_fit"`.
#'   Default `"trapezoidal"`. A failed, non-converged or non-physical Gaussian
#'   fit emits a warning and returns the trapezoidal area instead.
#'
#' @return Numeric. Baseline-subtracted integrated peak area.
#'
#' @examples
#' spec <- ls_simulate_spectrum(elements = c(Ca = 5000), seed = 1)
#' ls_peak_area(spec, 393.37)
#' @export
ls_peak_area <- function(x, center_nm, window_nm = 1,
                         method = "trapezoidal") {
  .validate_spectrum(x)
  .check_number(center_nm, "center_nm", min = min(x$wavelength),
                max = max(x$wavelength))
  .check_number(window_nm, "window_nm", min = .Machine$double.eps)
  method <- match.arg(method, c("trapezoidal", "gaussian_fit"))
  y <- .mean_intensity(x)
  wl <- x$wavelength
  channel_spacing <- if (length(wl) > 1) stats::median(diff(wl)) else 1
  # Ensure the window covers at least 5 channels
  effective_window <- max(window_nm, 5 * channel_spacing)
  lo <- center_nm - effective_window / 2
  hi <- center_nm + effective_window / 2
  idx <- which(wl >= lo & wl <= hi)
  if (length(idx) < 3) {
    # Fall back: use the closest 5 channels
    closest <- which.min(abs(wl - center_nm))
    half <- 2
    idx <- seq(max(1, closest - half), min(length(wl), closest + half))
  }
  if (length(idx) < 3) return(0)
  wl_seg <- wl[idx]
  y_seg <- y[idx]
  bl <- stats::approx(x = c(wl_seg[1], wl_seg[length(wl_seg)]),
                      y = c(y_seg[1], y_seg[length(y_seg)]),
                      xout = wl_seg)$y
  y_corr <- y_seg - bl
  if (method == "trapezoidal") {
    return(max(0, .trapz(wl_seg, y_corr)))
  }
  # gaussian_fit: fit y ~ A*exp(-((wl - mu)^2 / (2*sigma^2))) using nls
  mu0 <- wl_seg[which.max(y_corr)]
  sigma0 <- window_nm / 4
  A0 <- max(y_corr)
  if (A0 <= 0) return(0)
  failure <- NULL
  fit <- tryCatch(
    stats::nls(y_corr ~ A * exp(-((wl_seg - mu)^2) / (2 * sigma^2)),
               start = list(A = A0, mu = mu0, sigma = sigma0),
               control = stats::nls.control(warnOnly = FALSE)),
    error = function(e) {
      failure <<- conditionMessage(e)
      NULL
    }
  )
  co <- if (!is.null(fit)) stats::coef(fit) else NULL
  # Area under Gaussian = A * sigma * sqrt(2*pi)
  area <- if (!is.null(co)) co[["A"]] * abs(co[["sigma"]]) * sqrt(2 * pi) else NA_real_
  if (is.null(fit) || !isTRUE(fit$convInfo$isConv) ||
      any(!is.finite(co)) || co[["A"]] < 0 || co[["sigma"]] == 0 ||
      co[["mu"]] < min(wl_seg) || co[["mu"]] > max(wl_seg) || !is.finite(area)) {
    cli::cli_warn("Gaussian peak fit failed ({failure %||% 'invalid fitted parameters'}); using the trapezoidal area.",
                  class = "libscanR_peak_fit_warning")
    return(max(0, .trapz(wl_seg, y_corr)))
  }
  area
}

# -----------------------------------------------------------------------------
# Internal peak helpers
# -----------------------------------------------------------------------------

#' @keywords internal
#' @noRd
.peak_prominence <- function(y, i) {
  n <- length(y)
  h <- y[i]
  # Walk left until we cross a higher value or hit boundary
  left_min <- h
  j <- i - 1
  while (j >= 1) {
    if (y[j] > h) break
    if (y[j] < left_min) left_min <- y[j]
    j <- j - 1
  }
  right_min <- h
  j <- i + 1
  while (j <= n) {
    if (y[j] > h) break
    if (y[j] < right_min) right_min <- y[j]
    j <- j + 1
  }
  h - max(left_min, right_min)
}

#' @keywords internal
#' @noRd
.peak_fwhm <- function(wl, y, i) {
  n <- length(y)
  if (i <= 1L || i >= n) return(NA_real_)
  # Width at half prominence is invariant to a constant continuum offset.
  half <- y[i] - .peak_prominence(y, i) / 2
  # Find left crossing
  left_x <- NA_real_
  for (j in (i - 1):1) {
    if (y[j] <= half) {
      # Linear interpolate
      if (y[j + 1] == y[j]) {
        left_x <- wl[j]
      } else {
        left_x <- wl[j] + (half - y[j]) / (y[j + 1] - y[j]) * (wl[j + 1] - wl[j])
      }
      break
    }
  }
  right_x <- NA_real_
  for (j in (i + 1):n) {
    if (y[j] <= half) {
      if (y[j - 1] == y[j]) {
        right_x <- wl[j]
      } else {
        right_x <- wl[j - 1] + (half - y[j - 1]) / (y[j] - y[j - 1]) * (wl[j] - wl[j - 1])
      }
      break
    }
  }
  if (is.na(left_x) || is.na(right_x)) return(NA_real_)
  right_x - left_x
}

#' @keywords internal
#' @noRd
.peak_area_local <- function(wl, y, center, width) {
  lo <- center - width / 2
  hi <- center + width / 2
  idx <- which(wl >= lo & wl <= hi)
  if (length(idx) < 3) return(0)
  wl_seg <- wl[idx]
  y_seg <- y[idx]
  bl <- stats::approx(x = c(wl_seg[1], wl_seg[length(wl_seg)]),
                      y = c(y_seg[1], y_seg[length(y_seg)]),
                      xout = wl_seg)$y
  max(0, .trapz(wl_seg, y_seg - bl))
}
