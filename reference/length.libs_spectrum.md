# Number of Channels in a LIBS Spectrum

Number of Channels in a LIBS Spectrum

## Usage

``` r
# S3 method for class 'libs_spectrum'
length(x)
```

## Arguments

- x:

  A `libs_spectrum` object.

## Value

Integer scalar.

## Examples

``` r
spec <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1)
length(spec)
#> [1] 2048
```
