# Crop Spectral Range

Subsets a spectrum or dataset to a wavelength range.

## Usage

``` r
ls_crop(x, min_nm = NULL, max_nm = NULL)
```

## Arguments

- x:

  A
  [`ls_spectrum()`](https://cttir.github.io/libscanR/reference/ls_spectrum.md)
  or
  [`ls_dataset()`](https://cttir.github.io/libscanR/reference/ls_dataset.md)
  object.

- min_nm:

  Numeric. Minimum wavelength (nm). Default `NULL` = no lower bound.

- max_nm:

  Numeric. Maximum wavelength (nm). Default `NULL` = no upper bound.

## Value

Same class as input, cropped.

## Examples

``` r
spec <- ls_simulate_spectrum(seed = 1)
ls_crop(spec, 380, 450)
#> <libs_spectrum>
#> • Range: 380.21-449.98 nm (205 channels)
#> • Shots: 10
#> • Sample: "simulated" (synthetic)
#> • Baseline corrected: FALSE
```
