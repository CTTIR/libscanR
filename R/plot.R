# Spectrum plotting
# -----------------------------------------------------------------------------

#' Plot a LIBS Spectrum
#'
#' Generic spectrum plotter. Returns a ggplot2 object.
#'
#' @param x A [ls_spectrum()] object.
#' @param show_peaks Logical. Annotate detected peaks. Default `FALSE`.
#' @param show_elements Character vector of element symbols to highlight
#'   as dashed vertical lines with labels. Default `NULL`.
#' @param normalize Logical. Divide intensity by its positive maximum before plotting.
#'   Default `FALSE`.
#' @param snr_threshold Numeric. SNR threshold for peak annotation when
#'   `show_peaks = TRUE`. Default 5.
#' @param ... Additional arguments (currently unused).
#'
#' @return A ggplot2 object.
#'
#' @examples
#' spec <- ls_simulate_spectrum(seed = 1)
#' ls_plot_spectrum(spec, show_elements = "Ca")
#' @export
ls_plot_spectrum <- function(x, show_peaks = FALSE, show_elements = NULL,
                             normalize = FALSE, snr_threshold = 5, ...) {
  .validate_spectrum(x)
  .check_flag(normalize, "normalize")
  .check_flag(show_peaks, "show_peaks")
  inten <- .mean_intensity(x)
  divisor <- if (normalize && max(inten) > 0) max(inten) else 1
  inten <- inten / divisor

  df <- data.frame(wavelength_nm = x$wavelength, intensity = inten)

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$wavelength_nm,
                                        y = .data$intensity)) +
    ggplot2::geom_line(colour = "#2E86AB", linewidth = 0.4) +
    ggplot2::labs(x = "Wavelength (nm)", y = "Intensity (a.u.)") +
    theme_libs()

  if (show_peaks) {
    pk <- ls_find_peaks(x, snr_threshold = snr_threshold)
    if (nrow(pk) > 0) {
      pk$intensity <- pk$intensity / divisor
      p <- p + ggplot2::geom_point(
        data = pk,
        ggplot2::aes(x = .data$wavelength_nm, y = .data$intensity),
        colour = "#A23B72", size = 1.5
      )
    }
  }

  if (!is.null(show_elements)) {
    el <- ls_element_db(elements = show_elements,
                        range_nm = x$range_nm,
                        persistent_only = TRUE)
    if (nrow(el) > 0) {
      p <- p +
        ggplot2::geom_vline(data = el,
                            ggplot2::aes(xintercept = .data$wavelength_nm,
                                         colour = .data$element),
                            linetype = "dashed", alpha = 0.5) +
        ggplot2::scale_colour_brewer(palette = "Dark2", name = "Element")
    }
  }

  p
}

#' Overlay Multiple Spectra
#'
#' Plots multiple spectra on the same axes, optionally colored by a grouping
#' variable.
#'
#' @param dataset A [ls_dataset()] object.
#' @param color_by Character. Column in `sample_info` for color mapping.
#'   Default `NULL`.
#' @param normalize Logical. Divide each spectrum by its positive maximum. Default `FALSE`.
#' @param alpha Numeric. Line alpha. Default 0.5.
#'
#' @return A ggplot2 object.
#'
#' @examples
#' ds <- ls_example_data("tissue")
#' ls_plot_overlay(ds[1:10], color_by = "tissue")
#' @export
ls_plot_overlay <- function(dataset, color_by = NULL, normalize = FALSE,
                            alpha = 0.5) {
  .validate_dataset(dataset)
  wl <- dataset$wavelength
  rows <- lapply(seq_along(dataset$spectra), function(i) {
    s <- dataset$spectra[[i]]
    inten <- .mean_intensity(s)
    if (normalize && max(inten) > 0) inten <- inten / max(inten)
    sid <- dataset$sample_info$sample_id[i]
    data.frame(
      wavelength_nm = wl,
      intensity = inten,
      sample_id = sid,
      stringsAsFactors = FALSE
    )
  })
  df <- do.call(rbind, rows)

  if (!is.null(color_by)) {
    if (!color_by %in% names(dataset$sample_info)) {
      cli::cli_abort("{.arg color_by} column {.val {color_by}} not found.")
    }
    lookup <- stats::setNames(
      as.character(dataset$sample_info[[color_by]]),
      dataset$sample_info$sample_id
    )
    df$group <- lookup[df$sample_id]
    p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$wavelength_nm,
                                          y = .data$intensity,
                                          group = .data$sample_id,
                                          colour = .data$group)) +
      ggplot2::geom_line(alpha = alpha, linewidth = 0.3) +
      ggplot2::labs(x = "Wavelength (nm)", y = "Intensity (a.u.)",
                    colour = color_by) +
      ggplot2::scale_colour_brewer(palette = "Set1", na.value = "grey50") +
      theme_libs()
  } else {
    p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$wavelength_nm,
                                          y = .data$intensity,
                                          group = .data$sample_id)) +
      ggplot2::geom_line(alpha = alpha, linewidth = 0.3,
                         colour = "#2E86AB") +
      ggplot2::labs(x = "Wavelength (nm)", y = "Intensity (a.u.)") +
      theme_libs()
  }
  p
}

#' Plot a Spectral Region in Detail
#'
#' Zooms into a specified wavelength range and annotates peaks.
#'
#' @param x A [ls_spectrum()] or [ls_dataset()] object.
#' @param min_nm Numeric. Minimum wavelength (nm).
#' @param max_nm Numeric. Maximum wavelength (nm).
#' @param elements Optional character vector. Element symbols to annotate.
#'   Default `NULL` (auto-detect top peaks).
#' @param snr_threshold Numeric. SNR threshold for peak detection. Default 5.
#'
#' @return A ggplot2 object.
#'
#' @examples
#' spec <- ls_simulate_spectrum(seed = 1)
#' ls_plot_region(spec, 380, 410)
#' @export
ls_plot_region <- function(x, min_nm, max_nm, elements = NULL,
                           snr_threshold = 5) {
  if (inherits(x, "libs_dataset")) {
    cropped <- ls_crop(x, min_nm, max_nm)
    return(ls_plot_overlay(cropped))
  }
  .validate_spectrum(x)
  cropped <- ls_crop(x, min_nm, max_nm)

  pk <- ls_find_peaks(cropped, snr_threshold = snr_threshold)
  pk_id <- if (nrow(pk) > 0) ls_identify_peaks(pk, elements = elements) else pk

  df <- data.frame(
    wavelength_nm = cropped$wavelength,
    intensity = .mean_intensity(cropped)
  )
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$wavelength_nm,
                                        y = .data$intensity)) +
    ggplot2::geom_line(colour = "#2E86AB", linewidth = 0.5) +
    ggplot2::labs(x = "Wavelength (nm)", y = "Intensity (a.u.)") +
    theme_libs()

  if (nrow(pk_id) > 0 && "element" %in% names(pk_id)) {
    pk_lab <- pk_id[!is.na(pk_id$element), ]
    if (nrow(pk_lab) > 0) {
      p <- p +
        ggplot2::geom_text(
          data = pk_lab,
          ggplot2::aes(x = .data$wavelength_nm,
                       y = .data$intensity,
                       label = paste0(.data$element,
                                      ifelse(.data$ionization == 2, " II", " I"))),
          vjust = -0.5, hjust = 0, size = 3, colour = "#A23B72"
        )
    }
  }
  p
}
