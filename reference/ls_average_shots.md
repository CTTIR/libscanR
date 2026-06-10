# Average Replicate Shots

Averages shots within a
[`ls_spectrum()`](https://cttir.github.io/libscanR/reference/ls_spectrum.md).

## Usage

``` r
ls_average_shots(x, method = "mean", trim = 0, remove_outliers = FALSE)
```

## Arguments

- x:

  A
  [`ls_spectrum()`](https://cttir.github.io/libscanR/reference/ls_spectrum.md)
  object.

- method:

  Character. `"mean"` or `"median"`. Default `"mean"`.

- trim:

  Numeric. Fraction trimmed from each end for trimmed mean. Default 0.

- remove_outliers:

  Logical. Remove shots with deviation \> 3 SD from the per-channel
  mean. Default `FALSE`.

## Value

A `libs_spectrum` with a single averaged shot.

## Examples

``` r
spec <- ls_simulate_spectrum(n_shots = 10, seed = 1)
ls_average_shots(spec, remove_outliers = TRUE)
#> <libs_spectrum>
#> • Range: 200-900 nm (2048 channels)
#> • Shots: 1
#> • Sample: "simulated" (synthetic)
#> • Baseline corrected: FALSE
```
