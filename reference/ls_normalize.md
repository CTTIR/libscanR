# Normalize Spectra

Normalizes intensity values. Methods:

- `"total"` — divide each shot by total intensity

- `"max"` — divide by per-shot maximum

- `"snv"` — Standard Normal Variate: `(x - mean) / sd`

- `"internal_std"` — divide by intensity at a reference line

- `"area"` — divide by integrated (trapezoidal) area

## Usage

``` r
ls_normalize(x, method = "total", ref_wavelength = NULL, ref_window = 1)
```

## Arguments

- x:

  A
  [`ls_spectrum()`](https://cttir.github.io/libscanR/reference/ls_spectrum.md)
  or
  [`ls_dataset()`](https://cttir.github.io/libscanR/reference/ls_dataset.md)
  object.

- method:

  Character. Normalization method. Default `"total"`.

- ref_wavelength:

  Numeric. Required for `method = "internal_std"`.

- ref_window:

  Numeric. Window width (nm) around `ref_wavelength`. Default 1.

## Value

Same class as input with normalized intensities.

## Examples

``` r
spec <- ls_simulate_spectrum(seed = 1)
spec_n <- ls_normalize(spec, method = "total")
sum(spec_n$intensity[1, ])  # ~1
#> [1] 1
```
