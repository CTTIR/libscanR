# Number of Spectra in a Dataset

Number of Spectra in a Dataset

## Usage

``` r
# S3 method for class 'libs_dataset'
length(x)
```

## Arguments

- x:

  A `libs_dataset` object.

## Value

Integer scalar.

## Examples

``` r
ds <- ls_example_data("calibration")
length(ds)
#> [1] 27
```
