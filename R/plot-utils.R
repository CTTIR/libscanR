# Plot utilities: theme, scales
# -----------------------------------------------------------------------------

#' LIBS Theme for ggplot2
#'
#' A clean publication-ready theme for LIBS spectral plots.
#'
#' @param base_size Numeric. Base font size in points. Default 12.
#'
#' @return A ggplot2 theme object.
#'
#' @examples
#' ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) +
#'   ggplot2::geom_point() + theme_libs()
#' @export
theme_libs <- function(base_size = 12) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      strip.background = ggplot2::element_rect(fill = "#f0f0f0",
                                               colour = NA),
      legend.position = "right",
      plot.title = ggplot2::element_text(face = "bold"),
      axis.line = ggplot2::element_line(colour = "grey30"),
      axis.ticks = ggplot2::element_line(colour = "grey30"),
      # Extra right margin keeps the last x-axis tick label inside the device.
      plot.margin = ggplot2::margin(5.5, 14, 5.5, 5.5)
    )
}

#' Wavelength-Based Color Scale
#'
#' Maps wavelength values (nm) to approximate visible-light colors for
#' intuitive spectral visualization. Below 380 nm: UV purple; above 780 nm:
#' deep red.
#'
#' @param name Character. Legend title. Default `"Wavelength (nm)"`.
#' @param ... Additional arguments passed to
#'   [ggplot2::scale_color_gradientn()].
#'
#' @return A ggplot2 scale object.
#'
#' @examples
#' df <- data.frame(x = 1:5, y = 1:5, wl = c(200, 400, 550, 700, 850))
#' ggplot2::ggplot(df, ggplot2::aes(x, y, colour = wl)) +
#'   ggplot2::geom_point(size = 5) + scale_color_wavelength()
#' @export
scale_color_wavelength <- function(name = "Wavelength (nm)", ...) {
  # Anchor points spanning UV through IR
  anchors <- c(200, 380, 430, 490, 510, 580, 620, 700, 780, 900)
  cols <- c(
    "#4B0082", # deep UV purple
    "#8A2BE2",
    "#0000FF", # blue
    "#00FFFF", # cyan
    "#00FF00", # green
    "#FFFF00", # yellow
    "#FFA500", # orange
    "#FF0000", # red
    "#B22222", # deep red
    "#4B0000"
  )
  ggplot2::scale_color_gradientn(name = name, colours = cols,
                                 values = scales_rescale(anchors), ...)
}

# Minimal local rescale (avoid importing scales for this trivial op)
#' @keywords internal
#' @noRd
scales_rescale <- function(x) {
  (x - min(x)) / (max(x) - min(x))
}

# Colour-blind-safe discrete colour scale used by the package's plots.
# Up to eight groups use the Okabe-Ito colours shipped with grDevices
# (`grDevices::palette.colors(palette = "Okabe-Ito")`, R >= 4.0.0), with
# low-contrast yellow and black moved to the end; more groups fall back to
# the viridis discrete scale so no group is left without a colour.
# Palette source: Okabe M, Ito K (2008) Color Universal Design (CUD),
# https://jfly.uni-koeln.de/color/; reproduced in Wong B (2011) Points of
# view: Color blindness. Nat Methods 8(6):441, Fig. 2, p. 441,
# doi:10.1038/nmeth.1618.
#' @keywords internal
#' @noRd
.libs_discrete_colour <- function(n, name = ggplot2::waiver(), ...) {
  if (n <= 8L) {
    okabe_ito <- unname(grDevices::palette.colors(9L, palette = "Okabe-Ito"))
    values <- okabe_ito[c(2L, 3L, 4L, 6L, 7L, 8L, 5L, 1L)]
    ggplot2::scale_colour_manual(values = values, name = name, ...)
  } else {
    ggplot2::scale_colour_viridis_d(name = name, end = 0.9, ...)
  }
}

# Black or white text for labels drawn on tiles filled by `fill_scale`.
# The tile colour is taken from the scale's own palette after the default
# continuous rescaling (range of `values` to 0-1; a single distinct value maps
# to the midpoint), so the choice follows the colour the tile actually gets
# rather than the raw count. Tiles lighter than the middle of the CIELAB
# lightness scale (L* > 50) get black text, darker tiles white text.
#' @keywords internal
#' @noRd
.contrasting_label_colour <- function(values, fill_scale) {
  rng <- range(values, na.rm = TRUE)
  pos <- if (all(is.finite(rng)) && diff(rng) > 0) {
    (values - rng[1L]) / diff(rng)
  } else {
    rep(0.5, length(values))
  }
  fill <- fill_scale$palette(pos)
  lightness <- grDevices::convertColor(t(grDevices::col2rgb(fill)) / 255,
                                       from = "sRGB", to = "Lab")[, "L"]
  ifelse(lightness > 50, "black", "white")
}
