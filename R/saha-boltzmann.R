#' Relative Elemental Amounts under a Two-Stage LTE Model
#'
#' Estimates a common Boltzmann temperature and relative elemental number
#' fractions using explicit atomic and instrumental inputs. The Saha equation
#' accounts for the neutral/singly-ionized balance. This research calculation
#' requires optically thin emission, local thermodynamic equilibrium (LTE), a
#' common sampled plasma, stoichiometric ablation and corrected spectral response.
#' It does not establish those assumptions from an observed spectrum.
#'
#' @param x A [ls_spectrum()] with resolved, baseline-corrected lines.
#' @param elements Unique character vector of elements to include.
#' @param lines_nm Named list of measured line wavelengths per element.
#' @param electron_density Independently estimated electron density in cm^-3.
#'   Required; no density is assumed.
#' @param window_nm Integration width in nm. Default 0.5. Effective integration
#'   windows, including the coarse-channel expansion of [ls_peak_area()], must
#'   be disjoint, wholly inside the measured wavelength range and contain at
#'   least three measured channels each.
#' @param verbose Logical. Report the temperature and scope of the result.
#' @param atomic_data A data.frame with one unambiguous record per selected
#'   transition: `element`, `ionization` (1 = neutral, 2 = singly ionized),
#'   `wavelength_nm`, `wavelength_medium` (`"air"` or `"vacuum"`),
#'   `wavelength_vacuum_nm`, `A_s` (transition rate in s^-1), `g_upper`
#'   (statistical weight), `energy_upper_ev` (relative to that ion's ground
#'   state), `response` (measured signal per relative emitted intensity), and
#'   `source` (the transition reference). These data must be supplied explicitly;
#'   the bundled historical line compilation is insufficient for this calculation.
#'   For vacuum records the two wavelength columns must agree within
#'   `1e-8 + 1e-8 * wavelength_nm` nm (numerical rounding only).
#' @param partition_functions Named list, one entry per element. Each entry is
#'   a list with `neutral` and `ionized`, each either a function of temperature
#'   in kelvin returning the partition function, or an explicitly chosen positive
#'   constant approximation. Use the same statistical-weight convention as
#'   `g_upper` and include the relevant energy levels.
#' @param ionization_energies_ev Named positive numeric vector of first ionization
#'   energies in eV, one per element.
#' @param temperature_k Optional independently estimated common temperature in
#'   kelvin. If NULL, estimate it from a shared slope with a separate intercept
#'   per element/ion stage. Estimation requires a full-rank fit and positive
#'   residual degrees of freedom. Non-negative slopes are rejected.
#' @param intensity_scale `"energy"` (default) or `"photon"`, describing the
#'   response-corrected integrated intensities. Energy intensities require the
#'   vacuum-wavelength factor; photon counts do not.
#' @param wavelength_medium Medium of the measured axis. If NULL, read
#'   `x$metadata$wavelength_medium`; an unspecified medium is an error.
#' @param tolerance_nm Maximum difference between requested and reference
#'   wavelengths. Default 0.01. Multiple possible transitions are an error.
#'
#' @return A tibble with `element`, `temperature_k`, `concentration_rel`,
#'   `electron_density`, `n_lines`, `r_squared` and `log_population_sd`.
#'   Fractions are normalized only over the supplied elements, under a model
#'   that excludes molecules and charge states above +1; they are neither mass
#'   fractions nor absolute sample concentrations. `log_population_sd` measures
#'   line/stage disagreement on the log population scale, not calibrated
#'   uncertainty. Attributes `line_diagnostics`, `assumptions`, and
#'   `temperature_source` retain the calculation's inputs and limitations.
#'
#' @details
#' Earlier versions silently used unit statistical weights, omitted partition
#' functions and ignored electron density. Those outputs cannot be reused as
#' quantitative reference results. Supply verified physical inputs and refit.
#' A low residual does not verify LTE, optical thinness, absence of self-absorption,
#' spectral resolution, detector response or matrix-independent ablation.
#'
#' @references
#' NIST Atomic Spectra Database, spectral lines and Saha/LTE documentation:
#' <https://physics.nist.gov/PhysRefData/ASD/Html/lineshelp.html>.
#'
#' @examples
#' # A complete, explicitly synthetic forward-model example:
#' system.file("examples", "saha-boltzmann-synthetic.R", package = "libscanR")
#' @export
ls_saha_boltzmann <- function(x, elements, lines_nm,
                              electron_density = NULL,
                              window_nm = 0.5, verbose = TRUE,
                              atomic_data = NULL,
                              partition_functions = NULL,
                              ionization_energies_ev = NULL,
                              temperature_k = NULL,
                              intensity_scale = c("energy", "photon"),
                              wavelength_medium = NULL,
                              tolerance_nm = 0.01) {
  .validate_spectrum(x)
  if (!is.character(elements) || !length(elements) || anyNA(elements) ||
      any(!nzchar(elements)) || anyDuplicated(elements)) {
    cli::cli_abort("elements must contain unique, non-empty element labels.")
  }
  if (!is.list(lines_nm) || is.null(names(lines_nm)) ||
      anyDuplicated(names(lines_nm)) || !all(elements %in% names(lines_nm))) {
    cli::cli_abort("lines_nm must be a named list with one entry per element.")
  }
  requested <- lapply(elements, function(el) {
    values <- lines_nm[[el]]
    if (!is.numeric(values) || is.complex(values) || !length(values) ||
        any(!is.finite(values)) || anyDuplicated(values)) {
      cli::cli_abort("Each element needs distinct finite line wavelengths.")
    }
    if (any(values < min(x$wavelength) | values > max(x$wavelength))) {
      cli::cli_abort("No element quantified: a requested line is outside the measured range.")
    }
    data.frame(element = el, requested_nm = values)
  })
  requested <- do.call(rbind, requested)
  .check_flag(verbose, "verbose")
  .check_number(window_nm, "window_nm", min = .Machine$double.eps)
  .check_number(tolerance_nm, "tolerance_nm", min = 0)
  intensity_scale <- match.arg(intensity_scale)
  if (is.null(atomic_data) || is.null(partition_functions) ||
      is.null(ionization_energies_ev) || is.null(electron_density)) {
    cli::cli_abort(paste(
      "Supply atomic_data, partition_functions, ionization_energies_ev and electron_density.",
      "The historical bundled line data and assumed constants cannot establish elemental fractions."
    ))
  }
  .check_number(electron_density, "electron_density", min = .Machine$double.xmin)
  wavelength_medium <- wavelength_medium %||% .meta_get(x$metadata, "wavelength_medium", NULL)
  if (is.null(wavelength_medium)) cli::cli_abort("Specify the measured wavelength_medium (air or vacuum).")
  wavelength_medium <- match.arg(wavelength_medium, c("air", "vacuum"))
  selected <- .saha_lines(atomic_data, requested, wavelength_medium, tolerance_nm)
  width <- max(window_nm, 5 * stats::median(diff(x$wavelength)))
  centers <- selected$requested_nm
  if (any(centers - width / 2 < min(x$wavelength)) ||
      any(centers + width / 2 > max(x$wavelength)) ||
      any(diff(sort(centers)) < width)) {
    cli::cli_abort("Saha-Boltzmann line integration windows must be disjoint and fully measured.")
  }
  sampled <- vapply(centers, function(center) {
    sum(abs(x$wavelength - center) <= width / 2)
  }, integer(1))
  if (any(sampled < 3L)) {
    cli::cli_abort("Each Saha-Boltzmann integration window needs at least three measured channels.")
  }
  areas <- vapply(centers, function(center) ls_peak_area(x, center, window_nm), numeric(1))
  if (any(!is.finite(areas)) || any(areas <= 0)) {
    cli::cli_abort("Every selected line needs a positive finite integrated intensity; no lines were silently discarded.")
  }
  y <- log(areas) - log(selected$response) - log(selected$A_s) - log(selected$g_upper)
  if (intensity_scale == "energy") y <- y + log(selected$wavelength_vacuum_nm) + log(1e-9)
  energy <- selected$energy_upper_ev
  species <- factor(paste(selected$element, selected$ionization, sep = ":"))
  k_ev <- 8.617333262145e-5
  if (is.null(temperature_k)) {
    design <- cbind(stats::model.matrix(~ 0 + species), energy = energy)
    fit <- stats::lm.fit(design, y)
    if (fit$rank != ncol(design) || nrow(design) <= ncol(design)) {
      cli::cli_abort("Temperature estimation needs distinct upper energies and positive residual degrees of freedom.")
    }
    slope <- unname(utils::tail(fit$coefficients, 1))
    if (!is.finite(slope) || slope >= 0) {
      cli::cli_abort("The Boltzmann slope is not negative; a positive physical temperature cannot be inferred.")
    }
    temperature_k <- -1 / (k_ev * slope)
    temperature_source <- "shared Boltzmann slope with species intercepts"
  } else {
    temperature_source <- "supplied independently"
  }
  .check_number(temperature_k, "temperature_k", min = .Machine$double.xmin)
  populations <- .saha_populations(elements, partition_functions,
                                   ionization_energies_ev, temperature_k,
                                   electron_density)
  el_idx <- match(selected$element, elements)
  neutral <- selected$ionization == 1L
  log_u <- ifelse(neutral, log(populations$u_neutral[el_idx]),
                   log(populations$u_ionized[el_idx]))
  log_fraction <- ifelse(neutral, populations$log_neutral_fraction[el_idx],
                          populations$log_ionized_fraction[el_idx])
  log_amount <- y + energy / (k_ev * temperature_k) + log_u - log_fraction
  if (any(!is.finite(log_amount))) {
    cli::cli_abort("The supplied physical inputs exceed the numerical range of the population calculation.")
  }
  means <- vapply(elements, function(el) mean(log_amount[selected$element == el]), numeric(1))
  scaled <- exp(means - max(means))
  if (any(!is.finite(means)) || any(!is.finite(scaled)) || any(scaled <= 0)) {
    cli::cli_abort("Relative elemental populations cannot be represented with these physical inputs.")
  }
  relative <- scaled / sum(scaled)
  fitted_y <- means[el_idx] - log_u + log_fraction - energy / (k_ev * temperature_k)
  if (any(!is.finite(fitted_y)) || any(!is.finite(relative)) || any(relative <= 0)) {
    cli::cli_abort("Relative elemental populations cannot be represented with these physical inputs.")
  }
  out <- tibble::tibble(
    element = elements, temperature_k = temperature_k,
    concentration_rel = unname(relative), electron_density = electron_density,
    n_lines = vapply(elements, function(el) sum(selected$element == el), integer(1)),
    r_squared = vapply(elements, function(el) {
      idx <- selected$element == el
      .r_squared(y[idx], fitted_y[idx])
    }, numeric(1)),
    log_population_sd = vapply(elements, function(el) {
      stats::sd(log_amount[selected$element == el])
    }, numeric(1))
  )
  selected$integrated_intensity <- areas
  selected$effective_window_nm <- width
  selected$log_line_strength <- y
  selected$log_partition_function <- log_u
  selected$log_stage_fraction <- log_fraction
  selected$log_total_population <- log_amount
  selected$fitted_log_line_strength <- fitted_y
  selected$residual <- y - fitted_y
  attr(out, "line_diagnostics") <- tibble::as_tibble(selected)
  attr(out, "temperature_source") <- temperature_source
  attr(out, "assumptions") <- list(
    model = "neutral and singly ionized LTE populations only",
    required = c("optically thin emission", "local thermodynamic equilibrium",
                 "common sampled plasma", "stoichiometric ablation",
                 "resolved transitions and corrected instrument response"),
    normalized_over = elements, intensity_scale = intensity_scale,
    wavelength_medium = wavelength_medium,
    ionization_energies_ev = ionization_energies_ev[elements],
    partition_functions_at_temperature = populations,
    experimentally_verified = FALSE
  )
  if (verbose) cli::cli_inform("Two-stage LTE calculation at {signif(temperature_k, 5)} K; fractions cover only the supplied elements.")
  out
}

.saha_lines <- function(data, requested, medium, tolerance) {
  required <- c("element", "ionization", "wavelength_nm", "wavelength_medium",
                "wavelength_vacuum_nm", "A_s", "g_upper", "energy_upper_ev",
                "response", "source")
  if (!is.data.frame(data) || anyDuplicated(names(data)) ||
      !all(required %in% names(data))) {
    cli::cli_abort("atomic_data must include: {paste(required, collapse = ', ')}.")
  }
  positive <- c("wavelength_nm", "wavelength_vacuum_nm", "A_s", "g_upper",
                "response", "energy_upper_ev")
  for (name in positive) {
    value <- data[[name]]
    if (!is.numeric(value) || is.complex(value) || any(!is.finite(value)) ||
        any(value <= 0)) {
      cli::cli_abort("atomic_data${name} contains invalid physical values.")
    }
  }
  if (anyNA(data$ionization) || !all(data$ionization %in% c(1L, 2L)) ||
      any(data$g_upper != trunc(data$g_upper)) ||
      anyNA(data$element) || anyNA(data$wavelength_medium) ||
      !all(data$wavelength_medium %in% c("air", "vacuum")) ||
      anyNA(data$source) || any(!nzchar(trimws(as.character(data$source))))) {
    cli::cli_abort("Atomic stages, statistical weights, medium and source must be explicit and valid.")
  }
  vacuum <- data$wavelength_medium == "vacuum"
  if (any(abs(data$wavelength_vacuum_nm[vacuum] - data$wavelength_nm[vacuum]) >
          1e-8 + 1e-8 * data$wavelength_nm[vacuum])) {
    cli::cli_abort("Vacuum atomic records must have consistent wavelength_nm and wavelength_vacuum_nm.")
  }
  rows <- vapply(seq_len(nrow(requested)), function(i) {
    matches <- which(data$element == requested$element[i] &
                       data$wavelength_medium == medium &
                       abs(data$wavelength_nm - requested$requested_nm[i]) <= tolerance)
    if (length(matches) != 1L) {
      cli::cli_abort("Each requested line must match exactly one atomic transition in the measured medium.")
    }
    matches
  }, integer(1))
  if (anyDuplicated(rows)) cli::cli_abort("A transition cannot be counted twice.")
  out <- data[rows, required, drop = FALSE]
  out$requested_nm <- requested$requested_nm
  rownames(out) <- NULL
  out
}

.saha_populations <- function(elements, partitions, energies, temperature, density) {
  if (!is.list(partitions) || is.null(names(partitions)) ||
      anyDuplicated(names(partitions)) || !all(elements %in% names(partitions)) ||
      !is.numeric(energies) || is.complex(energies) || is.null(names(energies)) ||
      anyDuplicated(names(energies)) || !all(elements %in% names(energies)) ||
      any(!is.finite(energies)) || any(energies <= 0)) {
    cli::cli_abort("Supply named partition functions and positive first ionization energies for every element.")
  }
  get_u <- function(el, stage) {
    pair <- partitions[[el]]
    if (!is.list(pair) || anyDuplicated(names(pair)) || !stage %in% names(pair)) {
      cli::cli_abort("Partition functions for {el} need unique neutral and ionized entries.")
    }
    value <- pair[[stage]]
    if (is.function(value)) value <- value(temperature)
    .check_number(value, paste(el, stage, "partition function"), min = .Machine$double.xmin)
    value
  }
  u0 <- vapply(elements, get_u, numeric(1), stage = "neutral")
  u1 <- vapply(elements, get_u, numeric(1), stage = "ionized")
  # SI constants; convert density from cm^-3 to m^-3 before forming the ratio.
  log_ratio <- log(2) + 1.5 * (log(2 * pi) + log(9.1093837139e-31) +
    log(1.380649e-23) + log(temperature) - 2 * log(6.62607015e-34)) -
    log(density) - log(1e6) + log(u1) - log(u0) -
    energies[elements] / (8.617333262145e-5 * temperature)
  if (any(!is.finite(log_ratio))) {
    cli::cli_abort("The supplied physical inputs exceed the numerical range of the ion-stage calculation.")
  }
  log_sum <- pmax(log_ratio, 0) + log1p(exp(-abs(log_ratio)))
  data.frame(element = elements, u_neutral = unname(u0), u_ionized = unname(u1),
             log_neutral_fraction = unname(-log_sum),
             log_ionized_fraction = unname(log_ratio - log_sum))
}
