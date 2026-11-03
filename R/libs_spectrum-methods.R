#' Print a LIBS Spectrum
#'
#' @param x A `libs_spectrum` object.
#' @param ... Unused.
#' @return Invisibly returns `x`.
#' @export
print.libs_spectrum <- function(x, ...) {
  sid <- .meta_get(x$metadata, "sample_id", "unnamed")
  mat <- .meta_get(x$metadata, "material", NA)
  cli::cli_inform(c(
    "{.cls libs_spectrum}",
    "*" = "Range: {.val {round(x$range_nm[1], 2)}}-{.val {round(x$range_nm[2], 2)}} nm ({x$n_channels} channels)",
    "*" = "Shots: {x$n_shots}",
    "*" = "Sample: {.val {sid}}{if (!is.na(mat)) paste0(' (', mat, ')') else ''}",
    "*" = "Baseline corrected: {.val {!is.null(x[['baseline']])}}"
  ))
  invisible(x)
}

#' Summary of a LIBS Spectrum
#'
#' @param object A `libs_spectrum` object.
#' @param n_peaks Integer. Number of top peaks to show. Default 5.
#' @param ... Unused.
#' @return Invisibly returns a list with summary statistics.
#' @export
summary.libs_spectrum <- function(object, n_peaks = 5, ...) {
  inten <- .mean_intensity(object)
  peaks_idx <- order(inten, decreasing = TRUE)[seq_len(min(n_peaks, length(inten)))]
  top_peaks <- data.frame(
    wavelength_nm = round(object$wavelength[peaks_idx], 3),
    intensity = round(inten[peaks_idx], 2)
  )

  cli::cli_inform(c(
    "{.cls libs_spectrum} summary",
    "*" = "Range: {.val {round(object$range_nm[1], 2)}}-{.val {round(object$range_nm[2], 2)}} nm",
    "*" = "Channels: {object$n_channels}",
    "*" = "Shots: {object$n_shots}",
    "*" = "Max intensity: {.val {round(max(inten), 2)}}",
    "*" = "Mean intensity: {.val {round(mean(inten), 2)}}",
    "*" = "Top {n_peaks} peaks:"
  ))
  print(top_peaks, row.names = FALSE)

  invisible(list(
    range_nm = object$range_nm,
    n_channels = object$n_channels,
    n_shots = object$n_shots,
    max_intensity = max(inten),
    mean_intensity = mean(inten),
    top_peaks = top_peaks
  ))
}

#' Plot a LIBS Spectrum
#'
#' @param x A `libs_spectrum` object.
#' @param y Ignored.
#' @param ... Arguments passed to [ls_plot_spectrum()].
#' @return A `ggplot` object.
#' @export
plot.libs_spectrum <- function(x, y, ...) {
  ls_plot_spectrum(x, ...)
}

#' Subset a LIBS Spectrum by Wavelength
#'
#' Returns a new `libs_spectrum` with channels whose wavelengths fall in the
#' supplied numeric vector's range.
#'
#' @param x A `libs_spectrum` object.
#' @param i Numeric vector. Wavelengths are kept if they fall in
#'   `[min(i), max(i)]`. Can also be a logical or integer index into channels.
#' @return A new `libs_spectrum` object.
#' @export
`[.libs_spectrum` <- function(x, i) {
  .validate_spectrum(x)
  if (missing(i)) return(x)
  if (!length(i) || anyNA(i)) cli::cli_abort("Subsetting index must be non-empty and non-missing.")
  if (is.logical(i) && length(i) != x$n_channels) {
    cli::cli_abort("Logical index must have one value per channel.")
  }
  if (is.numeric(i) && (is.complex(i) || any(!is.finite(i)))) {
    cli::cli_abort("Numeric index must be finite real values.")
  }
  if (is.logical(i) || (is.numeric(i) && all(i == round(i)) && all(i > 0) &&
                        length(i) <= x$n_channels && max(i) <= x$n_channels)) {
    idx <- if (is.logical(i)) which(i) else as.integer(i)
  } else if (is.numeric(i)) {
    lo <- min(i); hi <- max(i)
    idx <- which(x$wavelength >= lo & x$wavelength <= hi)
  } else {
    cli::cli_abort("Subsetting index must be numeric or logical.")
  }
  if (length(idx) == 0) {
    cli::cli_abort("No channels match the subsetting index.")
  }
  ls_spectrum(
    wavelength = x$wavelength[idx],
    intensity = x$intensity[, idx, drop = FALSE],
    metadata = x$metadata,
    baseline = if (is.null(x[["baseline"]])) NULL else x[["baseline"]][idx]
  )
}

#' Combine Multiple LIBS Spectra by Stacking Shots
#'
#' Concatenates shots from multiple spectra. All spectra must share the same
#' wavelength axis. Shared metadata are retained; source metadata are stored
#' in `combined_metadata`. If every input has a baseline, the output stores
#' its shot-weighted mean; otherwise the aggregate baseline is unknown.
#'
#' @param ... Two or more `libs_spectrum` objects.
#' @return A new `libs_spectrum` with combined shots.
#' @export
c.libs_spectrum <- function(...) {
  args <- list(...)
  if (length(args) == 0) return(NULL)
  invisible(lapply(args, .validate_spectrum))
  if (length(args) == 1) return(args[[1]])

  wl <- args[[1]]$wavelength
  for (a in args[-1]) {
    if (!.same_axis(a$wavelength, wl)) {
      cli::cli_abort("All spectra must share the same wavelength axis.")
    }
  }
  mats <- lapply(args, function(a) a$intensity)
  combined <- do.call(rbind, mats)
  shared <- args[[1]]$metadata
  for (key in names(shared)) {
    if (!all(vapply(args, function(a) identical(a$metadata[[key]], shared[[key]]),
                    logical(1)))) shared[[key]] <- NULL
  }
  shared$combined_metadata <- lapply(args, function(a) a$metadata)
  baseline <- NULL
  if (all(vapply(args, function(a) !is.null(a[["baseline"]]), logical(1)))) {
    weights <- vapply(args, function(a) a$n_shots, numeric(1))
    baseline <- Reduce(`+`, Map(function(a, n) a[["baseline"]] * (n / sum(weights)),
                                args, weights))
  }
  ls_spectrum(wavelength = wl, intensity = combined,
              metadata = shared, baseline = baseline)
}

#' Number of Channels in a LIBS Spectrum
#'
#' @param x A `libs_spectrum` object.
#' @return Integer scalar.
#' @export
length.libs_spectrum <- function(x) {
  x$n_channels
}

#' Dimensions of a LIBS Spectrum (shots x channels)
#'
#' @param x A `libs_spectrum` object.
#' @return Integer vector of length 2.
#' @export
dim.libs_spectrum <- function(x) {
  c(x$n_shots, x$n_channels)
}
