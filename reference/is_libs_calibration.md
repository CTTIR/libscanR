# Test whether an object is a libs_calibration

Test whether an object is a libs_calibration

## Usage

``` r
is_libs_calibration(x)
```

## Arguments

- x:

  Object to test.

## Value

Logical scalar.

## Examples

``` r
ds <- ls_example_data("calibration")
cal <- ls_calibrate(ds, "Ca", 393.37, ds$sample_info$concentration,
                    verbose = FALSE)
is_libs_calibration(cal)
#> [1] TRUE
```
