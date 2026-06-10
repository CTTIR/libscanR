# Quantify Element Concentration

Applies a calibration model to unknown spectra.

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

  Numeric. Peak integration window. Defaults to 1 if NULL.

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
#>  1 std_00000_r1 Ca             1227.  ppm   FALSE     FALSE    
#>  2 std_00000_r2 Ca               12.3 ppm   FALSE     TRUE     
#>  3 std_00000_r3 Ca              483.  ppm   FALSE     FALSE    
#>  4 std_00100_r1 Ca               12.3 ppm   FALSE     TRUE     
#>  5 std_00100_r2 Ca               12.3 ppm   FALSE     TRUE     
#>  6 std_00100_r3 Ca               12.3 ppm   FALSE     TRUE     
#>  7 std_00250_r1 Ca               12.3 ppm   FALSE     TRUE     
#>  8 std_00250_r2 Ca              826.  ppm   FALSE     FALSE    
#>  9 std_00250_r3 Ca               12.3 ppm   FALSE     TRUE     
#> 10 std_00500_r1 Ca             1467.  ppm   FALSE     FALSE    
#> # ℹ 17 more rows
```
