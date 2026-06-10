# Plot Calibration Residuals

Standard regression diagnostic: residuals vs fitted.

## Usage

``` r
ls_plot_residuals(calibration)
```

## Arguments

- calibration:

  A
  [`ls_calibration()`](https://cttir.github.io/libscanR/reference/ls_calibration.md)
  object.

## Value

A ggplot2 object.

## Examples

``` r
ds <- ls_example_data("calibration")
conc <- ds$sample_info$concentration
cal <- ls_calibrate(ds, "Ca", 393.37, conc, verbose = FALSE)
ls_plot_residuals(cal)
```
