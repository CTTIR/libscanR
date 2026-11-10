# Summary of a LIBS Calibration

Summary of a LIBS Calibration

## Usage

``` r
# S3 method for class 'libs_calibration'
summary(object, ...)
```

## Arguments

- object:

  A `libs_calibration` object.

- ...:

  Unused.

## Value

Invisibly a list of key figures of merit.

## Examples

``` r
ds <- ls_example_data("calibration")
cal <- ls_calibrate(ds, "Ca", 393.37, ds$sample_info$concentration,
                    verbose = FALSE)
summary(cal)
#> <libs_calibration>
#> • Element: "Ca"
#> • Line: 393.37 nm
#> • Method: "univariate"
#> • Unit: "ppm"
#> • Standards: 27
#> • R-squared: 0.9122
#> • LOD: 3360 ppm
#> • LOQ: 11200 ppm
#> ℹ Model: concentration = 27.1251 + 849.342283 * intensity
```
