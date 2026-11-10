# Dimensions of a Dataset (spectra x channels)

Dimensions of a Dataset (spectra x channels)

## Usage

``` r
# S3 method for class 'libs_dataset'
dim(x)
```

## Arguments

- x:

  A `libs_dataset` object.

## Value

Integer vector of length 2.

## Examples

``` r
ds <- ls_example_data("calibration")
dim(ds)
#> [1]   27 1024
```
