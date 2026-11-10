# Test whether an object is a libs_dataset

Test whether an object is a libs_dataset

## Usage

``` r
is_libs_dataset(x)
```

## Arguments

- x:

  Object to test.

## Value

Logical scalar.

## Examples

``` r
ds <- ls_example_data("calibration")
is_libs_dataset(ds)
#> [1] TRUE
is_libs_dataset(list())
#> [1] FALSE
```
