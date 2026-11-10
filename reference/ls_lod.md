# Limit of Detection (3-sigma)

Calculates LOD using the 3-sigma criterion.

## Usage

``` r
ls_lod(calibration, blank = NULL, window_nm = NULL)
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
  residual standard error of the response-on-concentration calibration
  model. A supplied blank must contain at least two replicate shots on
  the fitted axis with the same preprocessing; its standard deviation is
  computed from the same integrated response (or internal-standard
  ratio) for each shot, not variation across wavelengths.

- window_nm:

  Optional window; `NULL` uses the fitted window. A different value is
  rejected.

## Value

Estimated numeric LOD in the calibration's concentration unit; `NA` for
PLS. This 3-sigma estimate requires independent confirmation near the
detection limit and is not an instrument qualification.

## Examples

``` r
ds <- ls_example_data("calibration")
conc <- ds$sample_info$concentration
cal <- ls_calibrate(ds, "Ca", 393.37, conc, verbose = FALSE)
ls_lod(cal)
#> [1] 3361.061
```
