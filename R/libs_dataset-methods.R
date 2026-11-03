#' Print a LIBS Dataset
#'
#' @param x A `libs_dataset` object.
#' @param ... Unused.
#' @return Invisibly returns `x`.
#' @export
print.libs_dataset <- function(x, ...) {
  group_col <- intersect(c("group", "material", "tissue", "class"),
                         names(x$sample_info))
  n_groups <- if (length(group_col) > 0) {
    length(unique(x$sample_info[[group_col[1]]]))
  } else NA_integer_

  cli::cli_inform(c(
    "{.cls libs_dataset}",
    "*" = "Spectra: {x$n_spectra}",
    "*" = "Channels: {x$n_channels}",
    "*" = "Range: {.val {round(x$range_nm[1], 2)}}-{.val {round(x$range_nm[2], 2)}} nm",
    "*" = if (!is.na(n_groups)) "Groups: {n_groups} ({group_col[1]})" else "Groups: (no grouping column)"
  ))
  invisible(x)
}

#' Summary of a LIBS Dataset
#'
#' @param object A `libs_dataset` object.
#' @param ... Unused.
#' @return Invisibly returns a list with per-group statistics.
#' @export
summary.libs_dataset <- function(object, ...) {
  group_col <- intersect(c("group", "material", "tissue", "class"),
                         names(object$sample_info))

  cli::cli_inform(c(
    "{.cls libs_dataset} summary",
    "*" = "Spectra: {object$n_spectra}",
    "*" = "Channels: {object$n_channels}",
    "*" = "Range: {.val {round(object$range_nm[1], 2)}}-{.val {round(object$range_nm[2], 2)}} nm"
  ))

  if (length(group_col) > 0) {
    gc <- group_col[1]
    tbl <- as.data.frame(table(object$sample_info[[gc]]))
    names(tbl) <- c(gc, "n")
    cli::cli_inform(c("i" = "Group counts (column {.val {gc}}):"))
    print(tbl, row.names = FALSE)
  }

  max_ints <- apply(object$intensity_matrix, 1, max)
  cli::cli_inform(c(
    "i" = "Per-spectrum max intensity: median = {.val {round(stats::median(max_ints), 2)}}, range = {.val {round(min(max_ints), 2)}}-{.val {round(max(max_ints), 2)}}"
  ))

  invisible(list(
    n_spectra = object$n_spectra,
    n_channels = object$n_channels,
    range_nm = object$range_nm,
    group_col = if (length(group_col) > 0) group_col[1] else NULL,
    sample_info = object$sample_info
  ))
}

#' Subset a LIBS Dataset
#'
#' @param x A `libs_dataset` object.
#' @param i Integer or logical index of spectra to keep.
#' @return A new `libs_dataset`.
#' @export
`[.libs_dataset` <- function(x, i) {
  .validate_dataset(x)
  if (missing(i)) return(x)
  if (!length(i) || anyNA(i) || !(is.logical(i) || is.numeric(i))) {
    cli::cli_abort("Dataset index must be non-empty numeric or logical values without NA.")
  }
  if (is.logical(i) && length(i) != x$n_spectra) {
    cli::cli_abort("Logical index must have one value per spectrum.")
  }
  if (is.numeric(i) && (is.complex(i) || any(!is.finite(i)) ||
      any(i != trunc(i)) || any(abs(i) > x$n_spectra))) {
    cli::cli_abort("Dataset index must contain whole in-range positions.")
  }
  new_spectra <- x$spectra[i]
  new_info <- x$sample_info[i, , drop = FALSE]
  ls_dataset(new_spectra, sample_info = new_info)
}

#' Number of Spectra in a Dataset
#' @param x A `libs_dataset` object.
#' @return Integer scalar.
#' @export
length.libs_dataset <- function(x) {
  x$n_spectra
}

#' Dimensions of a Dataset (spectra x channels)
#' @param x A `libs_dataset` object.
#' @return Integer vector of length 2.
#' @export
dim.libs_dataset <- function(x) {
  c(x$n_spectra, x$n_channels)
}

#' Plot a LIBS Dataset
#' @param x A `libs_dataset` object.
#' @param y Ignored.
#' @param ... Passed to [ls_plot_overlay()].
#' @return A `ggplot` object.
#' @export
plot.libs_dataset <- function(x, y, ...) {
  ls_plot_overlay(x, ...)
}
