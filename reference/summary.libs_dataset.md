# Summary of a LIBS Dataset

Summary of a LIBS Dataset

## Usage

``` r
# S3 method for class 'libs_dataset'
summary(object, ...)
```

## Arguments

- object:

  A `libs_dataset` object.

- ...:

  Unused.

## Value

Invisibly returns a list with per-group statistics.

## Examples

``` r
ds <- ls_example_data("calibration")
summary(ds)
#> <libs_dataset> summary
#> • Spectra: 27
#> • Channels: 1024
#> • Range: 200-900 nm
#> ℹ Group counts (column "group"):
#>     group  n
#>  standard 27
#> ℹ Per-spectrum max intensity: median = 101.73, range = 95.18-113.16
```
