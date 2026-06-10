# Plot a Calibration Curve

Plot a Calibration Curve

## Usage

``` r
ls_plot_calibration(
  calibration,
  show_lod = TRUE,
  show_loq = TRUE,
  show_prediction_interval = TRUE
)
```

## Arguments

- calibration:

  A
  [`ls_calibration()`](https://cttir.github.io/libscanR/reference/ls_calibration.md)
  object (univariate/internal_std).

- show_lod:

  Logical. Show LOD as a horizontal dashed line. Default `TRUE`.

- show_loq:

  Logical. Show LOQ as a horizontal dashed line. Default `TRUE`.

- show_prediction_interval:

  Logical. Show 95% prediction band. Default `TRUE`.

## Value

A ggplot2 object.

## Examples

``` r
ds <- ls_example_data("calibration")
conc <- ds$sample_info$concentration
cal <- ls_calibrate(ds, "Ca", 393.37, conc, verbose = FALSE)
ls_plot_calibration(cal)
```
