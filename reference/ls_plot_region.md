# Plot a Spectral Region in Detail

Zooms into a specified wavelength range and annotates peaks.

## Usage

``` r
ls_plot_region(x, min_nm, max_nm, elements = NULL, snr_threshold = 5)
```

## Arguments

- x:

  A
  [`ls_spectrum()`](https://cttir.github.io/libscanR/reference/ls_spectrum.md)
  or
  [`ls_dataset()`](https://cttir.github.io/libscanR/reference/ls_dataset.md)
  object.

- min_nm:

  Numeric. Minimum wavelength (nm).

- max_nm:

  Numeric. Maximum wavelength (nm).

- elements:

  Optional character vector. Element symbols to annotate. Default `NULL`
  (auto-detect top peaks).

- snr_threshold:

  Numeric. SNR threshold for peak detection. Default 5.

## Value

A ggplot2 object.

## Examples

``` r
spec <- ls_simulate_spectrum(seed = 1)
ls_plot_region(spec, 380, 410)
```
