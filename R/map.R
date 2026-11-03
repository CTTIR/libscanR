# Spatial mapping
# -----------------------------------------------------------------------------

#' Build a Spatial Elemental Map
#'
#' Constructs a spatial map from LIBS line-scan or raster-scan data. The
#' dataset's `sample_info` must include `x_pos` and `y_pos` columns.
#' Coordinates must be finite numeric values and each pair must be unique;
#' aggregate replicate positions explicitly before mapping them.
#'
#' @param dataset A [ls_dataset()] object with spatial coordinates.
#' @param element Character. Element label (for metadata).
#' @param line_nm Numeric. Emission line wavelength (nm).
#' @param calibration Optional [ls_calibration()]. If provided, intensities
#'   are converted to concentration. Default `NULL`.
#' @param window_nm Optional integration window. `NULL` reuses the calibration's
#'   fitted window, or 1 nm for an uncalibrated map.
#'
#' @return A list with S3 class `libs_map` containing `x`, `y`, `values`,
#'   `element`, `line_nm`, `unit`, and a rasterized `grid` matrix when the
#'   points form a regular grid.
#'
#' @examples
#' ds <- ls_example_data("spatial")
#' m <- ls_build_map(ds, "Ca", 393.37)
#' dim(m$grid)
#' @export
ls_build_map <- function(dataset, element, line_nm,
                         calibration = NULL, window_nm = NULL) {
  .validate_dataset(dataset)
  info <- dataset$sample_info
  if (!all(c("x_pos", "y_pos") %in% names(info))) {
    cli::cli_abort("{.arg dataset$sample_info} must contain {.val x_pos} and {.val y_pos} columns.")
  }
  xs <- info$x_pos
  ys <- info$y_pos
  if (!is.numeric(xs) || !is.numeric(ys) || is.complex(xs) || is.complex(ys) ||
      any(!is.finite(xs)) || any(!is.finite(ys))) {
    cli::cli_abort("Map coordinates must be finite numeric values.")
  }
  if (anyDuplicated(info[, c("x_pos", "y_pos")])) {
    cli::cli_abort("Map coordinate pairs must be unique; aggregate replicate positions explicitly.")
  }

  unit <- "a.u. nm"
  if (!is.null(calibration)) {
    if (!inherits(calibration, "libs_calibration")) {
      cli::cli_abort("calibration must be a libs_calibration model.")
    }
    if (!identical(calibration$element, element) ||
        !isTRUE(all.equal(calibration$wavelength_nm, line_nm, tolerance = 0))) {
      cli::cli_abort("The calibration element and line must match the requested map.")
    }
    intens <- ls_quantify(calibration, dataset, window_nm = window_nm)$concentration
    unit <- calibration$unit
  } else {
    intens <- vapply(dataset$spectra, function(s) {
      ls_peak_area(s, line_nm, window_nm %||% 1)
    }, numeric(1))
  }

  # Try to build a regular grid if coordinates allow
  grid_mat <- NULL
  ux <- sort(unique(xs))
  uy <- sort(unique(ys))
  if (length(ux) * length(uy) == length(xs)) {
    grid_mat <- matrix(NA_real_, nrow = length(uy), ncol = length(ux))
    for (k in seq_along(xs)) {
      ix <- match(xs[k], ux)
      iy <- match(ys[k], uy)
      grid_mat[iy, ix] <- intens[k]
    }
    rownames(grid_mat) <- uy
    colnames(grid_mat) <- ux
  }

  structure(
    list(
      x = xs,
      y = ys,
      values = intens,
      element = element,
      line_nm = line_nm,
      unit = unit,
      grid = grid_mat,
      sample_info = info
    ),
    class = "libs_map"
  )
}

#' Build Maps for Multiple Elements
#'
#' @param dataset A [ls_dataset()] object with spatial coordinates.
#' @param elements Character vector. Elements to map.
#' @param lines_nm Named numeric vector: wavelength per element (e.g.
#'   `c(Ca = 393.37, Fe = 371.99)`).
#' @param calibrations Named list of [ls_calibration()] objects. Default `NULL`.
#' @param window_nm Optional integration window. `NULL` reuses each calibration's
#'   fitted window, or 1 nm for uncalibrated maps.
#'
#' @return A named list of `libs_map` objects.
#'
#' @examples
#' ds <- ls_example_data("spatial")
#' ls_map_elements(ds, c("Ca", "Fe"),
#'                 c(Ca = 393.37, Fe = 371.99))
#' @export
ls_map_elements <- function(dataset, elements, lines_nm,
                            calibrations = NULL, window_nm = NULL) {
  .validate_dataset(dataset)
  if (is.null(names(lines_nm)) || !all(elements %in% names(lines_nm))) {
    cli::cli_abort("{.arg lines_nm} must be a named numeric vector covering all {.arg elements}.")
  }
  out <- list()
  for (el in elements) {
    cal <- if (!is.null(calibrations)) calibrations[[el]] else NULL
    out[[el]] <- ls_build_map(dataset, element = el,
                              line_nm = lines_nm[[el]],
                              calibration = cal,
                              window_nm = window_nm)
  }
  out
}

#' @export
print.libs_map <- function(x, ...) {
  cli::cli_inform(c(
    "{.cls libs_map}",
    "*" = "Element: {.val {x$element}}",
    "*" = "Line: {.val {x$line_nm}} nm",
    "*" = "Points: {length(x$values)}",
    "*" = "Range: {.val {signif(min(x$values, na.rm = TRUE), 3)}}-{.val {signif(max(x$values, na.rm = TRUE), 3)}} {x$unit}",
    "*" = "Grid: {if (!is.null(x$grid)) paste0(nrow(x$grid), 'x', ncol(x$grid)) else 'irregular'}"
  ))
  invisible(x)
}
