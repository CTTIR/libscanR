# Summary of a LIBS Spectrum

Summary of a LIBS Spectrum

## Usage

``` r
# S3 method for class 'libs_spectrum'
summary(object, n_peaks = 5, ...)
```

## Arguments

- object:

  A `libs_spectrum` object.

- n_peaks:

  Integer. Number of top peaks to show. Default 5.

- ...:

  Unused.

## Value

Invisibly returns a list with summary statistics.

## Examples

``` r
spec <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1)
summary(spec, n_peaks = 3)
#> <libs_spectrum> summary
#> • Range: 200-900 nm
#> • Channels: 2048
#> • Shots: 10
#> • Max intensity: 97.06
#> • Mean intensity: 56.15
#> • Top 3 peaks:
#>  wavelength_nm intensity
#>        201.710     97.06
#>        203.078     97.01
#>        200.000     96.81
```
