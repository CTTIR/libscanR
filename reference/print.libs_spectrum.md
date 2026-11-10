# Print a LIBS Spectrum

Print a LIBS Spectrum

## Usage

``` r
# S3 method for class 'libs_spectrum'
print(x, ...)
```

## Arguments

- x:

  A `libs_spectrum` object.

- ...:

  Unused.

## Value

Invisibly returns `x`.

## Examples

``` r
spec <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1)
print(spec)
#> <libs_spectrum>
#> • Range: 200-900 nm (2048 channels)
#> • Shots: 10
#> • Sample: "simulated" (synthetic)
#> • Baseline corrected: FALSE
```
