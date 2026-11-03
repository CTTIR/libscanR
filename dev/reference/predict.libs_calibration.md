# Predict Concentrations from a Calibration Model

Predict Concentrations from a Calibration Model

## Usage

``` r
# S3 method for class 'libs_calibration'
predict(object, newdata, ...)
```

## Arguments

- object:

  A `libs_calibration` object.

- newdata:

  A finite numeric vector of already integrated responses (ratios for
  internal-standard calibration), or a matrix with the fitted PLS
  columns in their trained order. This low-level method cannot verify
  wavelength labels; use
  [`ls_quantify()`](https://cttir.github.io/libscanR/dev/reference/ls_quantify.md)
  for spectra with checked feature identity.

- ...:

  Unused.

## Value

Numeric vector of predicted concentrations.
