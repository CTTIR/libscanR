#' Fictional Peaks for Software Demonstrations
#'
#' Returns invented peak strengths at the package's existing teaching and
#' heuristic integration windows. Component names are labels used by the
#' example scenarios, not validated elemental identifications. This table is
#' not derived from an atomic database: it contains no transition rates,
#' energy levels or statistical weights, and must not be used as a reference
#' for experimental spectra. It is accepted only as explicit simulation input.
#'
#' @return A tibble with `component`, `wavelength_nm` and `relative_strength`.
#'   Every strength is the arbitrary multiplier 0.001.
#' @examples
#' peaks <- ls_demo_peaks()
#' spec <- ls_simulate_spectrum(seed = 1, line_data = peaks)
#' ls_plot_spectrum(spec)
#' @export
ls_demo_peaks <- function() {
  centers <- c(.tissue_lines, Sr = 407)
  tibble::tibble(component = names(centers), wavelength_nm = unname(centers),
                 relative_strength = rep(0.001, length(centers)))
}

.validate_demo_peaks <- function(x) {
  required <- c("component", "wavelength_nm", "relative_strength")
  if (!is.data.frame(x) || anyDuplicated(names(x)) || !all(required %in% names(x)) ||
      !is.character(x$component) || anyNA(x$component) || any(!nzchar(x$component))) {
    cli::cli_abort("line_data must be an explicit teaching table with component, wavelength_nm and relative_strength columns.")
  }
  for (name in required[-1]) {
    values <- x[[name]]
    if (!is.numeric(values) || is.complex(values) || !is.null(dim(values)) ||
        any(!is.finite(values)) || any(values < 0) ||
        (name == "wavelength_nm" && any(values == 0))) {
      cli::cli_abort("Teaching peak column {.val {name}} contains invalid values.")
    }
  }
  tibble::as_tibble(x[required])
}
