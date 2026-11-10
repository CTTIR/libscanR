# Subset a LIBS Spectrum by Wavelength

Returns a new `libs_spectrum` with channels whose wavelengths fall in
the supplied numeric vector's range.

## Usage

``` r
# S3 method for class 'libs_spectrum'
x[i]
```

## Arguments

- x:

  A `libs_spectrum` object.

- i:

  Numeric vector. Wavelengths are kept if they fall in
  `[min(i), max(i)]`. Can also be a logical or integer index into
  channels.

## Value

A new `libs_spectrum` object.

## Examples

``` r
spec <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1)
ca_region <- spec[c(380, 420)]
length(ca_region)
#> [1] 2
```
