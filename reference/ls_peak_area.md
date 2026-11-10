# Calculate Peak Area

Integrates peak area at a given emission line, with a local baseline
subtracted (linear interpolation between window edges).

## Usage

``` r
ls_peak_area(x, center_nm, window_nm = 1, method = "trapezoidal")
```

## Arguments

- x:

  A
  [`ls_spectrum()`](https://cttir.github.io/libscanR/reference/ls_spectrum.md)
  object.

- center_nm:

  Numeric. Peak center wavelength (nm).

- window_nm:

  Numeric. Integration window width. Default 1. To support coarsely
  sampled input, the effective window is at least five median channel
  spacings, with up to five nearest channels used at edges. This does
  not resolve overlapping lines; inspect instrument resolution and the
  integration region before interpreting an area as an element.

- method:

  Character. `"trapezoidal"` or `"gaussian_fit"`. Default
  `"trapezoidal"`. A failed, non-converged or non-physical Gaussian fit
  emits a warning and returns the trapezoidal area instead.

## Value

Numeric. Baseline-subtracted integrated peak area.

## Examples

``` r
spec <- ls_simulate_spectrum(line_data = ls_demo_peaks(),
                             elements = c(Ca = 5000), seed = 1)
ls_peak_area(spec, 393.37)
#> [1] 2.250182
```
