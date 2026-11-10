# Simulate a LIBS Spectrum

Generates a demonstration LIBS spectrum with configurable elemental
composition, noise, and continuum background. Emission lines are drawn
from the user-configured atomic reference
([`ls_element_db()`](https://cttir.github.io/libscanR/reference/ls_element_db.md))
and modelled as Gaussian peaks. Peak widths are at least 2.5 channel
spacings so coarse demonstrations remain visible; this is not an
instrument response model or validation of quantitative elemental
concentrations or tissue identity.

## Usage

``` r
ls_simulate_spectrum(
  elements = c(Ca = 5000, Fe = 200, Na = 1000),
  wavelength_range = c(200, 900),
  n_channels = 2048,
  n_shots = 10,
  noise_level = 0.02,
  continuum_level = 100,
  shot_rsd = 0.1,
  fwhm_nm = 0.1,
  seed = NULL,
  line_data = NULL
)
```

## Arguments

- elements:

  Named numeric vector. Element concentrations (arbitrary units,
  interpreted as relative intensity scaling). Default
  `c(Ca = 5000, Fe = 200, Na = 1000)`.

- wavelength_range:

  Numeric vector of length 2. Range in nm. Default `c(200, 900)`.

- n_channels:

  Integer. Number of spectral channels. Default 2048.

- n_shots:

  Integer. Number of replicate shots. Default 10.

- noise_level:

  Numeric. Relative noise level (fraction of max intensity). Default
  0.02.

- continuum_level:

  Numeric. Continuum background level. Default 100.

- shot_rsd:

  Numeric. Relative standard deviation of shot-to-shot intensity
  variation (0-1). Default 0.1.

- fwhm_nm:

  Numeric. Typical line FWHM in nm. Default 0.1.

- seed:

  Optional integer random seed for reproducibility.

- line_data:

  Optional explicit teaching peak table, with `component`,
  `wavelength_nm` and `relative_strength` columns. Strengths are
  arbitrary intensity multipliers, not atomic transition probabilities.
  Use
  [`ls_demo_peaks()`](https://cttir.github.io/libscanR/reference/ls_demo_peaks.md)
  for a fictional fixture. `NULL` uses the configured atomic reference
  and retains the transition-rate scaling convention.

## Value

A
[`ls_spectrum()`](https://cttir.github.io/libscanR/reference/ls_spectrum.md)
object.

## Examples

``` r
spec <- ls_simulate_spectrum(line_data = ls_demo_peaks(),
                             elements = c(Ca = 1000, Na = 500), seed = 1)
print(spec)
#> <libs_spectrum>
#> • Range: 200-900 nm (2048 channels)
#> • Shots: 10
#> • Sample: "simulated" (synthetic)
#> • Baseline corrected: FALSE
```
