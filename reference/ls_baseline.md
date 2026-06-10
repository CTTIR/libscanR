# Baseline Correction

Removes continuum/baseline drift from LIBS spectra. Supported methods:
`"snip"` (Statistics-sensitive Non-linear Iterative Peak-clipping,
Morhac/Ryan), `"als"` (Asymmetric Least Squares smoothing, Eilers &
Boelens), `"rolling_ball"` (morphological), `"linear"` (two-endpoint
interpolation), or `"polynomial"` (low-order polynomial fit of
baseline-only regions).

## Usage

``` r
ls_baseline(
  x,
  method = "snip",
  iterations = 100,
  order = 3,
  lambda = 1e+05,
  p = 0.01,
  radius = 50,
  ...
)
```

## Arguments

- x:

  A
  [`ls_spectrum()`](https://cttir.github.io/libscanR/reference/ls_spectrum.md)
  or
  [`ls_dataset()`](https://cttir.github.io/libscanR/reference/ls_dataset.md)
  object.

- method:

  Character. One of `"snip"`, `"als"`, `"rolling_ball"`, `"linear"`,
  `"polynomial"`. Default `"snip"`.

- iterations:

  Integer. Iterations for iterative methods (SNIP, ALS). Default 100.

- order:

  Integer. Polynomial order for `"polynomial"`. Default 3.

- lambda:

  Numeric. Smoothness parameter for ALS. Default `1e5`.

- p:

  Numeric. Asymmetry parameter for ALS (0 \< p \< 1). Default 0.01.

- radius:

  Integer. Rolling-ball radius in channels. Default 50.

- ...:

  Reserved for future use.

## Value

Same class as input with baseline-corrected intensities; the estimated
baseline is stored in the `baseline` element for inspection.

## Examples

``` r
spec <- ls_simulate_spectrum(seed = 1)
corr <- ls_baseline(spec, method = "snip")
is.null(corr$baseline)
#> [1] FALSE
```
