# Subset a LIBS Dataset

Subset a LIBS Dataset

## Usage

``` r
# S3 method for class 'libs_dataset'
x[i]
```

## Arguments

- x:

  A `libs_dataset` object.

- i:

  Integer or logical index of spectra to keep.

## Value

A new `libs_dataset`.

## Examples

``` r
ds <- ls_example_data("calibration")
first_two <- ds[1:2]
length(first_two)
#> [1] 2
```
