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

  Numeric. Integration window width. Default 1.

- method:

  Character. `"trapezoidal"` or `"gaussian_fit"`. Default
  `"trapezoidal"`.

## Value

Numeric. Baseline-subtracted integrated peak area.

## Examples

``` r
spec <- ls_simulate_spectrum(elements = c(Ca = 5000), seed = 1)
ls_peak_area(spec, 393.37)
#> [1] 3.466782
```
