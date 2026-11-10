# Quantify Element Concentration

Applies a calibration model using its saved wavelength axis,
preprocessing and extraction contract. Legacy models without this
contract must be refitted. Unavailable detection-limit flags are `NA`,
not FALSE.

## Usage

``` r
ls_quantify(calibration, x, window_nm = NULL)
```

## Arguments

- calibration:

  A
  [`ls_calibration()`](https://cttir.github.io/libscanR/reference/ls_calibration.md)
  object.

- x:

  A
  [`ls_spectrum()`](https://cttir.github.io/libscanR/reference/ls_spectrum.md)
  or
  [`ls_dataset()`](https://cttir.github.io/libscanR/reference/ls_dataset.md)
  object.

- window_nm:

  Optional numeric integration window. `NULL` reuses the fitted window;
  a different supplied value is rejected.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns `sample_id`, `element`, `concentration`, `unit`,
`below_lod`, `below_loq`.

## Examples

``` r
ds <- ls_example_data("calibration")
conc <- ds$sample_info$concentration
cal <- ls_calibrate(ds, "Ca", 393.37, conc, verbose = FALSE)
ls_quantify(cal, ds)
#> # A tibble: 27 × 6
#>    sample_id    element concentration unit  below_lod below_loq
#>    <chr>        <chr>           <dbl> <chr> <lgl>     <lgl>    
#>  1 std_00000_r1 Ca             1708.  ppm   TRUE      TRUE     
#>  2 std_00000_r2 Ca               27.1 ppm   TRUE      TRUE     
#>  3 std_00000_r3 Ca              679.  ppm   TRUE      TRUE     
#>  4 std_00100_r1 Ca               27.1 ppm   TRUE      TRUE     
#>  5 std_00100_r2 Ca               27.1 ppm   TRUE      TRUE     
#>  6 std_00100_r3 Ca               27.1 ppm   TRUE      TRUE     
#>  7 std_00250_r1 Ca               27.1 ppm   TRUE      TRUE     
#>  8 std_00250_r2 Ca             1057.  ppm   TRUE      TRUE     
#>  9 std_00250_r3 Ca               27.1 ppm   TRUE      TRUE     
#> 10 std_00500_r1 Ca             1858.  ppm   TRUE      TRUE     
#> # ℹ 17 more rows
```
