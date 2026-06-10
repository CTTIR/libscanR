# Limit of Detection (3-sigma)

Calculates LOD using the 3-sigma criterion.

## Usage

``` r
ls_lod(calibration, blank = NULL, window_nm = 1)
```

## Arguments

- calibration:

  A
  [`ls_calibration()`](https://cttir.github.io/libscanR/reference/ls_calibration.md)
  object.

- blank:

  Optional
  [`ls_spectrum()`](https://cttir.github.io/libscanR/reference/ls_spectrum.md)
  of a blank sample. If `NULL` (the default), LOD is recomputed from the
  residual standard error of the calibration model.

- window_nm:

  Numeric. Integration window for the blank. Default 1.

## Value

Numeric LOD in the calibration's concentration unit.

## Examples

``` r
ds <- ls_example_data("calibration")
conc <- ds$sample_info$concentration
cal <- ls_calibrate(ds, "Ca", 393.37, conc, verbose = FALSE)
ls_lod(cal)
#> [1] 3.957456
```
