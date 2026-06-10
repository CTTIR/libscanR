# Smooth Spectra

Applies spectral smoothing. Methods: `"savgol"` (Savitzky-Golay, needs
the `signal` package; otherwise falls back to moving average with a
warning), `"moving_avg"`, `"gaussian"`, `"median"`.

## Usage

``` r
ls_smooth(x, method = "savgol", window = 11, poly_order = 3)
```

## Arguments

- x:

  A
  [`ls_spectrum()`](https://cttir.github.io/libscanR/reference/ls_spectrum.md)
  or
  [`ls_dataset()`](https://cttir.github.io/libscanR/reference/ls_dataset.md)
  object.

- method:

  Character. Default `"savgol"`.

- window:

  Integer. Window size in channels (odd preferred). Default 11.

- poly_order:

  Integer. Polynomial order for Savitzky-Golay. Default 3.

## Value

Same class as input with smoothed intensities.

## Examples

``` r
spec <- ls_simulate_spectrum(seed = 1)
sm <- ls_smooth(spec, method = "moving_avg", window = 9)
```
