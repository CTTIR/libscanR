# Elemental map plotting
# -----------------------------------------------------------------------------

#' Plot an Elemental Map
#'
#' @param map A `libs_map` object from [ls_build_map()].
#' @param color_scale Character. `"viridis"`, `"magma"`, `"plasma"`,
#'   `"inferno"`, `"hot"`, `"jet"`. Default `"viridis"`.
#' @param title Character. Plot title. Default: element symbol.
#'
#' @return A ggplot2 object.
#'
#' @examples
#' ds <- ls_example_data("spatial")
#' m <- ls_build_map(ds, "Ca", 393.37)
#' ls_plot_map(m)
#' @export
ls_plot_map <- function(map, color_scale = "viridis", title = NULL) {
  if (!inherits(map, "libs_map")) {
    cli::cli_abort("{.arg map} must be a {.cls libs_map}.")
  }
  color_scale <- match.arg(color_scale,
                           c("viridis", "magma", "plasma", "inferno",
                             "hot", "jet"))
  if (is.null(title)) title <- paste0(map$element, " @ ",
                                      round(map$line_nm, 2), " nm")
  df <- data.frame(x = map$x, y = map$y, value = map$values)

  if (!is.null(map$grid)) {
    p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$x, y = .data$y,
                                          fill = .data$value)) +
      ggplot2::geom_raster(interpolate = FALSE)
  } else {
    p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$x, y = .data$y,
                                          colour = .data$value)) +
      ggplot2::geom_point(size = 3)
  }
  p <- p +
    .map_color_scale(color_scale, map$unit, fill = !is.null(map$grid)) +
    ggplot2::labs(title = title, x = "x position", y = "y position") +
    ggplot2::coord_equal() +
    theme_libs()
  p
}

#' Plot Multi-Element Map Panel
#'
#' Plots multiple elemental maps as a faceted panel.
#'
#' @param maps Named list of `libs_map` objects.
#' @param ncol Integer. Facet columns. Default 3.
#'
#' @return A ggplot2 object.
#'
#' @examples
#' ds <- ls_example_data("spatial")
#' ms <- ls_map_elements(ds, c("Ca", "Fe", "Zn"),
#'                       c(Ca = 393.37, Fe = 371.99, Zn = 213.86))
#' ls_plot_map_panel(ms)
#' @export
ls_plot_map_panel <- function(maps, ncol = 3) {
  if (!is.list(maps) || length(maps) == 0) {
    cli::cli_abort("{.arg maps} must be a non-empty list.")
  }
  ok <- vapply(maps, inherits, logical(1), "libs_map")
  if (!all(ok)) {
    cli::cli_abort("All entries in {.arg maps} must be {.cls libs_map}.")
  }

  rows <- lapply(seq_along(maps), function(i) {
    m <- maps[[i]]
    # Normalize within each map to 0..1 so a shared scale is meaningful
    v <- m$values
    rng <- range(v, na.rm = TRUE)
    v_norm <- if (diff(rng) == 0) rep(0, length(v)) else (v - rng[1]) / diff(rng)
    data.frame(x = m$x, y = m$y, value = v, value_norm = v_norm,
               element = paste0(m$element, " (", round(m$line_nm, 1), " nm)"))
  })
  df <- do.call(rbind, rows)

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$x, y = .data$y,
                                        fill = .data$value_norm))
  has_grid <- !is.null(maps[[1]]$grid)
  if (has_grid) {
    p <- p + ggplot2::geom_raster(interpolate = FALSE)
  } else {
    p <- p + ggplot2::geom_tile()
  }

  p +
    ggplot2::facet_wrap(~ .data$element, ncol = ncol) +
    ggplot2::scale_fill_viridis_c(name = "Relative\n(min-max\nper map)",
                                  option = "viridis") +
    ggplot2::labs(x = "x position", y = "y position") +
    ggplot2::coord_equal() +
    theme_libs()
}

# -----------------------------------------------------------------------------
# Internal: color scales
# -----------------------------------------------------------------------------

#' @keywords internal
#' @noRd
.map_color_scale <- function(scale, unit, fill = TRUE) {
  if (scale %in% c("viridis", "magma", "plasma", "inferno")) {
    if (fill) {
      return(ggplot2::scale_fill_viridis_c(option = scale, name = unit))
    }
    return(ggplot2::scale_colour_viridis_c(option = scale, name = unit))
  }
  if (scale == "hot") {
    cols <- grDevices::heat.colors(64)
  } else {
    cols <- c("#000080", "#0000FF", "#00FFFF", "#FFFF00",
              "#FF7F00", "#FF0000", "#7F0000")
  }
  if (fill) {
    ggplot2::scale_fill_gradientn(colours = cols, name = unit)
  } else {
    ggplot2::scale_colour_gradientn(colours = cols, name = unit)
  }
}

#' Plot an Element Map (alias)
#'
#' Convenience alias for [ls_plot_map()].
#'
#' @param map A `libs_map` object.
#' @param ... Passed to [ls_plot_map()].
#' @return A ggplot2 object.
#' @examples
#' ds <- ls_example_data("spatial")
#' ls_plot_element_map(ls_build_map(ds, "Ca", 393.37))
#' @export
ls_plot_element_map <- function(map, ...) {
  ls_plot_map(map, ...)
}
