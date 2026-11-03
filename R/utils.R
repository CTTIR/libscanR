# Internal helper functions (not exported)

#' Validate a libs_spectrum object
#' @param x Object to validate
#' @param arg Argument name for error message
#' @keywords internal
#' @noRd
.validate_spectrum <- function(x, arg = "x") {
  if (!inherits(x, "libs_spectrum")) {
    cli::cli_abort(c(
      "{.arg {arg}} must be a {.cls libs_spectrum} object.",
      "x" = "You supplied a {.cls {class(x)[1]}}."
    ))
  }
  .check_wavelength(x$wavelength)
  .check_metadata(x$metadata)
  if (is.unsorted(x$wavelength, strictly = TRUE) ||
      !is.matrix(x$intensity) || !is.numeric(x$intensity) ||
      is.complex(x$intensity) || any(!is.finite(x$intensity)) ||
      nrow(x$intensity) < 1L ||
      ncol(x$intensity) != length(x$wavelength) ||
      !.same_count(x$n_shots, nrow(x$intensity)) ||
      !.same_count(x$n_channels, length(x$wavelength)) ||
      !identical(as.numeric(x$range_nm), range(x$wavelength))) {
    cli::cli_abort("Invalid {.cls libs_spectrum} structure; rebuild it with {.fn ls_spectrum}.")
  }
  if (!is.null(x$baseline) &&
      (!is.numeric(x$baseline) || is.complex(x$baseline) ||
       !is.null(dim(x$baseline)) || any(!is.finite(x$baseline)) ||
       length(x$baseline) != x$n_channels)) {
    cli::cli_abort("Invalid spectrum baseline; rebuild it with {.fn ls_spectrum}.")
  }
  invisible(TRUE)
}

#' Validate a libs_dataset object
#' @keywords internal
#' @noRd
.validate_dataset <- function(x, arg = "x") {
  if (!inherits(x, "libs_dataset")) {
    cli::cli_abort(c(
      "{.arg {arg}} must be a {.cls libs_dataset} object.",
      "x" = "You supplied a {.cls {class(x)[1]}}."
    ))
  }
  if (!is.list(x$spectra) || !length(x$spectra)) {
    cli::cli_abort("Invalid dataset spectra; rebuild with {.fn ls_dataset}.")
  }
  invisible(lapply(x$spectra, .validate_spectrum))
  ids <- unname(vapply(x$spectra, function(s) {
    .sample_id(s$metadata$sample_id, allow_missing = FALSE)
  }, character(1)))
  axes_match <- vapply(x$spectra, function(s) {
    .same_axis(s$wavelength, x$wavelength)
  }, logical(1))
  if (anyDuplicated(ids) || !all(axes_match) ||
      !is.data.frame(x$sample_info) ||
      !identical(as.character(x$sample_info$sample_id), ids) ||
      !.same_count(x$n_spectra, length(x$spectra)) ||
      !.same_count(x$n_channels, length(x$wavelength)) ||
      !identical(as.numeric(x$range_nm), range(x$wavelength)) ||
      !isTRUE(all.equal(x$intensity_matrix,
                       .build_intensity_matrix(x$spectra), tolerance = 0))) {
    cli::cli_abort("Invalid or stale dataset alignment; rebuild with {.fn ls_dataset}.")
  }
  invisible(TRUE)
}

.check_wavelength <- function(wavelength) {
  if (!is.numeric(wavelength) || is.complex(wavelength) ||
      !is.null(dim(wavelength)) || length(wavelength) < 2L ||
      any(!is.finite(wavelength)) || any(wavelength <= 0) ||
      anyDuplicated(wavelength)) {
    cli::cli_abort("{.arg wavelength} must be a numeric vector of at least 2 distinct, finite, positive channels.")
  }
  invisible(TRUE)
}

.check_metadata <- function(metadata) {
  if (!is.list(metadata) || is.data.frame(metadata) ||
      (length(metadata) && (is.null(names(metadata)) ||
        anyNA(names(metadata)) || any(!nzchar(names(metadata))) ||
        anyDuplicated(names(metadata))))) {
    cli::cli_abort("{.arg metadata} must be a list with unique, non-empty names.")
  }
  invisible(TRUE)
}

.sample_id <- function(id, allow_missing = TRUE) {
  if (is.null(id) && allow_missing) return(NA_character_)
  if (length(id) != 1L || !(is.character(id) || is.factor(id) ||
      is.numeric(id)) || is.complex(id) || !is.null(dim(id))) {
    cli::cli_abort("Each sample_id must be a single character or numeric value.")
  }
  id <- as.character(id)
  if (is.na(id) || !nzchar(trimws(id))) {
    if (allow_missing) return(NA_character_)
    cli::cli_abort("sample_id must not be missing or empty.")
  }
  id
}

.same_axis <- function(x, y) identical(as.numeric(x), as.numeric(y))

.same_count <- function(x, expected) {
  is.numeric(x) && !is.complex(x) && is.null(dim(x)) &&
    length(x) == 1L && is.finite(x) && x == expected
}

.check_number <- function(x, name, min = -Inf, max = Inf, integer = FALSE) {
  if (!is.numeric(x) || is.complex(x) || length(x) != 1L ||
      !is.null(dim(x)) || !is.finite(x) || x < min || x > max ||
      (integer && x != trunc(x))) {
    cli::cli_abort("{.arg {name}} must be a finite {if (integer) 'integer' else 'number'} between {min} and {max}.")
  }
  invisible(TRUE)
}

.check_flag <- function(x, name) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    cli::cli_abort("{.arg {name}} must be TRUE or FALSE.")
  }
  invisible(TRUE)
}

#' Convert a wavelength (nm) to an index on a wavelength axis
#' @param wavelength Numeric vector (wavelength axis)
#' @param nm Numeric scalar wavelength value
#' @return Integer index of closest channel
#' @keywords internal
#' @noRd
.wavelength_to_idx <- function(wavelength, nm) {
  which.min(abs(wavelength - nm))
}

#' Get intensity vector for a spectrum (mean across shots if multi-shot)
#' @keywords internal
#' @noRd
.mean_intensity <- function(x) {
  if (!is.matrix(x$intensity)) return(as.numeric(x$intensity))
  if (nrow(x$intensity) == 1) return(as.numeric(x$intensity[1, ]))
  colMeans(x$intensity)
}

#' Build intensity matrix for a list of spectra (one row per spectrum)
#' @keywords internal
#' @noRd
.build_intensity_matrix <- function(spectra) {
  mat <- do.call(rbind, lapply(spectra, .mean_intensity))
  rownames(mat) <- vapply(spectra, function(s) {
    id <- s$metadata$sample_id
    if (is.null(id)) NA_character_ else as.character(id)
  }, character(1))
  mat
}

#' Trapezoidal integration
#' @keywords internal
#' @noRd
.trapz <- function(x, y) {
  n <- length(x)
  if (n < 2) return(0)
  sum((x[-1] - x[-n]) * (y[-1] + y[-n]) / 2)
}

#' Estimate noise as median absolute deviation from a smoothed baseline
#' @keywords internal
#' @noRd
.estimate_noise <- function(y) {
  if (length(y) < 5) return(stats::sd(y, na.rm = TRUE))
  diffs <- diff(y)
  stats::mad(diffs, na.rm = TRUE) / sqrt(2)
}

#' Path to packaged extdata file
#' @keywords internal
#' @noRd
.extdata_path <- function(file) {
  system.file("extdata", file, package = "libscanR")
}

#' Ensure wavelength axis is sorted ascending
#' @keywords internal
#' @noRd
.ensure_sorted <- function(wavelength, intensity) {
  if (is.unsorted(wavelength)) {
    ord <- order(wavelength)
    wavelength <- wavelength[ord]
    if (is.matrix(intensity)) {
      intensity <- intensity[, ord, drop = FALSE]
    } else {
      intensity <- intensity[ord]
    }
  }
  list(wavelength = wavelength, intensity = intensity)
}

#' Safe requireNamespace with informative error
#' @keywords internal
#' @noRd
.require_pkg <- function(pkg, reason = NULL) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    msg <- c("Package {.pkg {pkg}} is required.")
    if (!is.null(reason)) msg <- c(msg, i = reason)
    msg <- c(msg, i = "Install it with {.code install.packages(\"{pkg}\")}.")
    cli::cli_abort(msg)
  }
  invisible(TRUE)
}

#' Compose a human-readable range string
#' @keywords internal
#' @noRd
.range_str <- function(x, digits = 1) {
  r <- range(x, na.rm = TRUE)
  sprintf("%.*f-%.*f", digits, r[1], digits, r[2])
}

#' Safe name getter from a metadata list
#' @keywords internal
#' @noRd
.meta_get <- function(meta, key, default = NA) {
  if (is.null(meta)) return(default)
  v <- meta[[key]]
  if (is.null(v)) default else v
}


.seed_scope <- function(seed) {
  if (is.null(seed)) return(function() invisible(NULL))
  .check_number(seed, "seed", min = -.Machine$integer.max,
                max = .Machine$integer.max, integer = TRUE)
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  old_seed <- if (had_seed) get(".Random.seed", envir = .GlobalEnv) else NULL
  set.seed(seed)
  function() {
    if (had_seed) assign(".Random.seed", old_seed, envir = .GlobalEnv) else {
      if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
        rm(".Random.seed", envir = .GlobalEnv)
      }
    }
    invisible(NULL)
  }
}
