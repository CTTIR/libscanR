# Fictional Peaks for Software Demonstrations

Returns invented peak strengths at the package's existing teaching and
heuristic integration windows. Component names are labels used by the
example scenarios, not validated elemental identifications. This table
is not derived from an atomic database: it contains no transition rates,
energy levels or statistical weights, and must not be used as a
reference for experimental spectra. It is accepted only as explicit
simulation input.

## Usage

``` r
ls_demo_peaks()
```

## Value

A tibble with `component`, `wavelength_nm` and `relative_strength`.
Every strength is the arbitrary multiplier 0.001.

## Examples

``` r
peaks <- ls_demo_peaks()
spec <- ls_simulate_spectrum(seed = 1, line_data = peaks)
ls_plot_spectrum(spec)
```
