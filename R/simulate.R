# Synthetic LIBS spectrum / dataset generator
# -----------------------------------------------------------------------------

#' Simulate a LIBS Spectrum
#'
#' Generates a demonstration LIBS spectrum with configurable elemental
#' composition, noise, and continuum background. Emission lines are drawn
#' from the internal NIST database ([ls_element_db()]) and modelled as
#' Gaussian peaks. Peak widths are at least 2.5 channel spacings so coarse
#' demonstrations remain visible; this is not an instrument response model
#' or validation of quantitative elemental concentrations or tissue identity.
#'
#' @param elements Named numeric vector. Element concentrations (arbitrary
#'   units, interpreted as relative intensity scaling). Default
#'   `c(Ca = 5000, Fe = 200, Na = 1000)`.
#' @param wavelength_range Numeric vector of length 2. Range in nm.
#'   Default `c(200, 900)`.
#' @param n_channels Integer. Number of spectral channels. Default 2048.
#' @param n_shots Integer. Number of replicate shots. Default 10.
#' @param noise_level Numeric. Relative noise level (fraction of max
#'   intensity). Default 0.02.
#' @param continuum_level Numeric. Continuum background level. Default 100.
#' @param shot_rsd Numeric. Relative standard deviation of shot-to-shot
#'   intensity variation (0-1). Default 0.1.
#' @param fwhm_nm Numeric. Typical line FWHM in nm. Default 0.1.
#' @param seed Optional integer random seed for reproducibility.
#'
#' @return A [ls_spectrum()] object.
#'
#' @examples
#' spec <- ls_simulate_spectrum(elements = c(Ca = 1000, Na = 500), seed = 1)
#' print(spec)
#' @export
ls_simulate_spectrum <- function(elements = c(Ca = 5000, Fe = 200, Na = 1000),
                                 wavelength_range = c(200, 900),
                                 n_channels = 2048, n_shots = 10,
                                 noise_level = 0.02, continuum_level = 100,
                                 shot_rsd = 0.1, fwhm_nm = 0.1,
                                 seed = NULL) {
  .check_number(n_channels, "n_channels", min = 2, integer = TRUE)
  .check_number(n_shots, "n_shots", min = 1, integer = TRUE)
  .check_number(noise_level, "noise_level", min = 0)
  .check_number(continuum_level, "continuum_level", min = 0)
  .check_number(shot_rsd, "shot_rsd", min = 0, max = 1)
  .check_number(fwhm_nm, "fwhm_nm", min = .Machine$double.eps)
  if (!is.numeric(wavelength_range) || length(wavelength_range) != 2L ||
      any(!is.finite(wavelength_range)) || any(wavelength_range <= 0) ||
      wavelength_range[1] >= wavelength_range[2]) {
    cli::cli_abort("wavelength_range must contain two finite positive, increasing limits.")
  }
  if (!is.numeric(elements) || is.complex(elements) || !length(elements) ||
      is.null(names(elements)) || anyNA(names(elements)) ||
      any(names(elements) == "") || anyDuplicated(names(elements)) ||
      any(!is.finite(elements)) || any(elements < 0)) {
    cli::cli_abort("{.arg elements} must be a named, finite, non-negative numeric vector with unique names.")
  }
  restore_seed <- .seed_scope(seed)
  on.exit(restore_seed(), add = TRUE)

  wl <- seq(wavelength_range[1], wavelength_range[2], length.out = n_channels)
  channel_spacing <- diff(wavelength_range) / (n_channels - 1)
  effective_fwhm <- max(fwhm_nm, 2.5 * channel_spacing)

  # Exponential continuum background
  continuum <- continuum_level * exp(-(wl - wavelength_range[1]) /
                                       diff(wavelength_range) * 1.2)

  # Fetch emission lines for specified elements
  db <- ls_element_db(elements = names(elements),
                      range_nm = wavelength_range)
  base_spec <- continuum
  sigma <- effective_fwhm / (2 * sqrt(2 * log(2)))

  for (el in names(elements)) {
    conc <- elements[[el]]
    lines_el <- db[db$element == el, ]
    if (nrow(lines_el) == 0) next
    # Scale factor: concentration * relative transition probability
    for (j in seq_len(nrow(lines_el))) {
      center <- lines_el$wavelength_nm[j]
      aki <- lines_el$aki[j]
      amp <- conc * aki * 1e-3
      if (amp <= 0) next
      # Gaussian demonstration profile
      base_spec <- base_spec + amp * exp(-((wl - center)^2) / (2 * sigma^2))
    }
  }

  peak_max <- max(base_spec)
  noise_sd <- noise_level * peak_max

  # Generate n_shots by applying per-shot scaling and adding noise
  intensity <- matrix(0, nrow = n_shots, ncol = n_channels)
  for (s in seq_len(n_shots)) {
    scale_factor <- stats::rnorm(1, 1, shot_rsd)
    if (scale_factor < 0.1) scale_factor <- 0.1
    noise <- stats::rnorm(n_channels, 0, noise_sd)
    intensity[s, ] <- base_spec * scale_factor + noise
  }
  intensity[intensity < 0] <- 0

  meta <- list(
    sample_id = "simulated",
    material = "synthetic",
    simulated = TRUE,
    elements = elements,
    wavelength_range_nm = wavelength_range,
    n_channels = n_channels,
    noise_level = noise_level,
    seed = seed
  )

  ls_spectrum(
    wavelength = wl,
    intensity = intensity,
    metadata = meta
  )
}

#' Generate Example LIBS Dataset
#'
#' Creates a synthetic `libs_dataset` suitable for demonstrating package
#' features. Scenarios:
#'
#' * `"tissue"` — 50 spectra from 5 tissue types (bone, liver, kidney,
#'   muscle, fat), 10 per type, with tissue-typical elemental signatures.
#' * `"calibration"` — 27 spectra of Ca standards (9 concentrations x 3
#'   replicates) with constant matrix (Na, K, Mg).
#' * `"spatial"` — 400 spectra on a 20x20 grid simulating a tissue
#'   cross-section with Ca/Fe gradients and a Zn-enriched hotspot.
#' * `"all"` — named list of the above.
#'
#' @param scenario Character. One of `"tissue"`, `"calibration"`, `"spatial"`,
#'   `"all"`. Default `"tissue"`.
#' @param seed Integer. Random seed. Default 42.
#' @param n_channels Integer. Number of spectral channels. Default 1024
#'   (reduced from 2048 for faster examples).
#'
#' @return A `libs_dataset` object (or named list for `"all"`).
#'
#' @examples
#' ds <- ls_example_data("tissue")
#' print(ds)
#' @export
ls_example_data <- function(scenario = c("tissue", "calibration", "spatial", "all"),
                            seed = 42, n_channels = 1024) {
  .check_number(n_channels, "n_channels", min = 2, integer = TRUE)
  .check_number(seed, "seed", min = -.Machine$integer.max,
                max = .Machine$integer.max - 500, integer = TRUE)
  restore_seed <- .seed_scope(seed)
  on.exit(restore_seed(), add = TRUE)
  scenario <- match.arg(scenario)
  if (scenario == "all") {
    return(list(
      tissue = ls_example_data("tissue", seed = seed, n_channels = n_channels),
      calibration = ls_example_data("calibration", seed = seed, n_channels = n_channels),
      spatial = ls_example_data("spatial", seed = seed, n_channels = n_channels)
    ))
  }
  switch(scenario,
         tissue = .example_tissue(seed, n_channels),
         calibration = .example_calibration(seed, n_channels),
         spatial = .example_spatial(seed, n_channels))
}

# -----------------------------------------------------------------------------
# Internal scenario constructors
# -----------------------------------------------------------------------------

#' @keywords internal
#' @noRd
.example_tissue <- function(seed, n_channels) {
  tissue_profiles <- list(
    bone = c(Ca = 200000, P = 100000, Mg = 5000, Na = 5000, Sr = 200),
    liver = c(Fe = 1500, Cu = 50, Zn = 200, K = 3000, Na = 2000, Ca = 300),
    kidney = c(K = 4000, Na = 3000, Ca = 500, Fe = 500, Zn = 100, Mg = 200),
    muscle = c(K = 3500, Na = 1000, Mg = 300, Fe = 100, Zn = 50, Ca = 150),
    fat = c(Na = 500, K = 200, Ca = 100, C = 5000)
  )
  n_per_tissue <- 10
  spectra <- list()
  info_rows <- list()
  counter <- 0
  for (tissue in names(tissue_profiles)) {
    base_conc <- tissue_profiles[[tissue]]
    for (r in seq_len(n_per_tissue)) {
      counter <- counter + 1
      # Add biological variation: 15% RSD per element
      conc <- base_conc * exp(stats::rnorm(length(base_conc), 0, 0.15))
      s <- ls_simulate_spectrum(
        elements = conc,
        n_channels = n_channels,
        n_shots = 5,
        seed = seed + counter
      )
      sid <- sprintf("%s_%02d", tissue, r)
      s$metadata$sample_id <- sid
      s$metadata$material <- tissue
      s$metadata$tissue <- tissue
      spectra[[counter]] <- s
      info_rows[[counter]] <- data.frame(
        sample_id = sid,
        material = tissue,
        tissue = tissue,
        replicate = r,
        stringsAsFactors = FALSE
      )
    }
  }
  info <- do.call(rbind, info_rows)
  ls_dataset(spectra, sample_info = info)
}

#' @keywords internal
#' @noRd
.example_calibration <- function(seed, n_channels) {
  concs <- c(0, 100, 250, 500, 1000, 2500, 5000, 7500, 10000)
  matrix_elems <- c(Na = 1000, K = 500, Mg = 200)
  n_rep <- 3
  spectra <- list()
  info_rows <- list()
  counter <- 0
  for (c_val in concs) {
    for (r in seq_len(n_rep)) {
      counter <- counter + 1
      elems <- c(Ca = c_val, matrix_elems)
      s <- ls_simulate_spectrum(
        elements = elems,
        n_channels = n_channels,
        n_shots = 5,
        seed = seed + counter
      )
      sid <- sprintf("std_%05d_r%d", c_val, r)
      s$metadata$sample_id <- sid
      s$metadata$material <- "Ca standard"
      s$metadata$concentration <- c_val
      spectra[[counter]] <- s
      info_rows[[counter]] <- data.frame(
        sample_id = sid,
        material = "Ca standard",
        concentration = c_val,
        replicate = r,
        group = "standard",
        stringsAsFactors = FALSE
      )
    }
  }
  info <- do.call(rbind, info_rows)
  ls_dataset(spectra, sample_info = info)
}

#' @keywords internal
#' @noRd
.example_spatial <- function(seed, n_channels) {
  grid_n <- 20
  coords <- expand.grid(x = seq_len(grid_n), y = seq_len(grid_n))
  spectra <- list()
  info_rows <- list()
  counter <- 0
  for (k in seq_len(nrow(coords))) {
    xp <- coords$x[k]
    yp <- coords$y[k]
    counter <- counter + 1
    # Ca: decreases L -> R, Fe: increases top -> bottom
    ca_val <- 5000 - (xp - 1) * 200
    fe_val <- 100 + (yp - 1) * 80
    # Zn hotspot centered at (8,8), width 3
    zn_val <- 50 + 2000 * exp(-((xp - 8)^2 + (yp - 8)^2) / (2 * 3^2))
    elems <- c(
      Ca = max(100, ca_val),
      Fe = max(50, fe_val),
      Zn = max(50, zn_val),
      Na = 800,
      K = 500
    )
    s <- ls_simulate_spectrum(
      elements = elems,
      n_channels = n_channels,
      n_shots = 3,
      seed = seed + counter
    )
    sid <- sprintf("px_%02d_%02d", xp, yp)
    s$metadata$sample_id <- sid
    s$metadata$material <- "tissue_section"
    s$metadata$x_pos <- xp
    s$metadata$y_pos <- yp
    spectra[[counter]] <- s
    info_rows[[counter]] <- data.frame(
      sample_id = sid,
      material = "tissue_section",
      x_pos = xp,
      y_pos = yp,
      stringsAsFactors = FALSE
    )
  }
  info <- do.call(rbind, info_rows)
  ls_dataset(spectra, sample_info = info)
}
