# Print a LIBS Dataset

Print a LIBS Dataset

## Usage

``` r
# S3 method for class 'libs_dataset'
print(x, ...)
```

## Arguments

- x:

  A `libs_dataset` object.

- ...:

  Unused.

## Value

Invisibly returns `x`.

## Examples

``` r
ds <- ls_example_data("calibration")
print(ds)
#> <libs_dataset>
#> • Spectra: 27
#> • Channels: 1024
#> • Range: 200-900 nm
#> • Groups: 1 (group)
```
