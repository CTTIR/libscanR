# Combine Multiple LIBS Spectra by Stacking Shots

Concatenates shots from multiple spectra. All spectra must share the
same wavelength axis. Shared metadata are retained; source metadata are
stored in `combined_metadata`. If every input has a baseline, the output
stores its shot-weighted mean; otherwise the aggregate baseline is
unknown.

## Usage

``` r
# S3 method for class 'libs_spectrum'
c(...)
```

## Arguments

- ...:

  Two or more `libs_spectrum` objects.

## Value

A new `libs_spectrum` with combined shots.
