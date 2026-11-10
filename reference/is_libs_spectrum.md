# Test whether an object is a libs_spectrum

Test whether an object is a libs_spectrum

## Usage

``` r
is_libs_spectrum(x)
```

## Arguments

- x:

  Object to test.

## Value

Logical scalar.

## Examples

``` r
spec <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1)
is_libs_spectrum(spec)
#> [1] TRUE
is_libs_spectrum(1:3)
#> [1] FALSE
```
