# Limit of Quantification (10-sigma)

Calculates LOQ using the 10-sigma criterion.

## Usage

``` r
ls_loq(calibration, blank = NULL, window_nm = 1)
```

## Arguments

- calibration:

  A
  [`ls_calibration()`](https://cttir.github.io/libscanR/reference/ls_calibration.md)
  object.

- blank:

  Optional
  [`ls_spectrum()`](https://cttir.github.io/libscanR/reference/ls_spectrum.md)
  of a blank sample.

- window_nm:

  Numeric. Integration window. Default 1.

## Value

Numeric LOQ in the calibration's concentration unit.

## Examples

``` r
ds <- ls_example_data("calibration")
conc <- ds$sample_info$concentration
cal <- ls_calibrate(ds, "Ca", 393.37, conc, verbose = FALSE)
ls_loq(cal)
#> [1] 13.19152
```
