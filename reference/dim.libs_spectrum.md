# Dimensions of a LIBS Spectrum (shots x channels)

Dimensions of a LIBS Spectrum (shots x channels)

## Usage

``` r
# S3 method for class 'libs_spectrum'
dim(x)
```

## Arguments

- x:

  A `libs_spectrum` object.

## Value

Integer vector of length 2.

## Examples

``` r
spec <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1)
dim(spec)
#> [1]   10 2048
```
