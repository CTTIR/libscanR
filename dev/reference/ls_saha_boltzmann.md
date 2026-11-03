# Relative Elemental Amounts under a Two-Stage LTE Model

Estimates a common Boltzmann temperature and relative elemental number
fractions using explicit atomic and instrumental inputs. The Saha
equation accounts for the neutral/singly-ionized balance. This research
calculation requires optically thin emission, local thermodynamic
equilibrium (LTE), a common sampled plasma, stoichiometric ablation and
corrected spectral response. It does not establish those assumptions
from an observed spectrum.

## Usage

``` r
ls_saha_boltzmann(
  x,
  elements,
  lines_nm,
  electron_density = NULL,
  window_nm = 0.5,
  verbose = TRUE,
  atomic_data = NULL,
  partition_functions = NULL,
  ionization_energies_ev = NULL,
  temperature_k = NULL,
  intensity_scale = c("energy", "photon"),
  wavelength_medium = NULL,
  tolerance_nm = 0.01
)
```

## Arguments

- x:

  A
  [`ls_spectrum()`](https://cttir.github.io/libscanR/dev/reference/ls_spectrum.md)
  with resolved, baseline-corrected lines.

- elements:

  Unique character vector of elements to include.

- lines_nm:

  Named list of measured line wavelengths per element.

- electron_density:

  Independently estimated electron density in cm^-3. Required; no
  density is assumed.

- window_nm:

  Integration width in nm. Default 0.5. Effective integration windows,
  including the coarse-channel expansion of
  [`ls_peak_area()`](https://cttir.github.io/libscanR/dev/reference/ls_peak_area.md),
  must be disjoint, wholly inside the measured wavelength range and
  contain at least three measured channels each.

- verbose:

  Logical. Report the temperature and scope of the result.

- atomic_data:

  A data.frame with one unambiguous record per selected transition:
  `element`, `ionization` (1 = neutral, 2 = singly ionized),
  `wavelength_nm`, `wavelength_medium` (`"air"` or `"vacuum"`),
  `wavelength_vacuum_nm`, `A_s` (transition rate in s^-1), `g_upper`
  (statistical weight), `energy_upper_ev` (relative to that ion's ground
  state), `response` (measured signal per relative emitted intensity),
  and `source` (the transition reference). These data must be supplied
  explicitly; the bundled historical line compilation is insufficient
  for this calculation. For vacuum records the two wavelength columns
  must agree within `1e-8 + 1e-8 * wavelength_nm` nm (numerical rounding
  only).

- partition_functions:

  Named list, one entry per element. Each entry is a list with `neutral`
  and `ionized`, each either a function of temperature in kelvin
  returning the partition function, or an explicitly chosen positive
  constant approximation. Use the same statistical-weight convention as
  `g_upper` and include the relevant energy levels.

- ionization_energies_ev:

  Named positive numeric vector of first ionization energies in eV, one
  per element.

- temperature_k:

  Optional independently estimated common temperature in kelvin. If
  NULL, estimate it from a shared slope with a separate intercept per
  element/ion stage. Estimation requires a full-rank fit and positive
  residual degrees of freedom. Non-negative slopes are rejected.

- intensity_scale:

  `"energy"` (default) or `"photon"`, describing the response-corrected
  integrated intensities. Energy intensities require the
  vacuum-wavelength factor; photon counts do not.

- wavelength_medium:

  Medium of the measured axis. If NULL, read
  `x$metadata$wavelength_medium`; an unspecified medium is an error.

- tolerance_nm:

  Maximum difference between requested and reference wavelengths.
  Default 0.01. Multiple possible transitions are an error.

## Value

A tibble with `element`, `temperature_k`, `concentration_rel`,
`electron_density`, `n_lines`, `r_squared` and `log_population_sd`.
Fractions are normalized only over the supplied elements, under a model
that excludes molecules and charge states above +1; they are neither
mass fractions nor absolute sample concentrations. `log_population_sd`
measures line/stage disagreement on the log population scale, not
calibrated uncertainty. Attributes `line_diagnostics`, `assumptions`,
and `temperature_source` retain the calculation's inputs and
limitations.

## Details

Earlier versions silently used unit statistical weights, omitted
partition functions and ignored electron density. Those outputs cannot
be reused as quantitative reference results. Supply verified physical
inputs and refit. A low residual does not verify LTE, optical thinness,
absence of self-absorption, spectral resolution, detector response or
matrix-independent ablation.

## References

NIST Atomic Spectra Database, spectral lines and Saha/LTE documentation:
<https://physics.nist.gov/PhysRefData/ASD/Html/lineshelp.html>.

## Examples

``` r
# A complete, explicitly synthetic forward-model example:
system.file("examples", "saha-boltzmann-synthetic.R", package = "libscanR")
#> [1] "/home/runner/work/_temp/Library/libscanR/examples/saha-boltzmann-synthetic.R"
```
