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
  [`ls_quantify()`](https://cttir.github.io/libscanR/reference/ls_quantify.md)
  for spectra with checked feature identity.

- ...:

  Unused.

## Value

Numeric vector of predicted concentrations.

## Examples

``` r
ds <- ls_example_data("calibration")
cal <- ls_calibrate(ds, "Ca", 393.37, ds$sample_info$concentration,
                    verbose = FALSE)
predict(cal, newdata = cal$intensities[1:3])
#> [1] 1707.85526   27.12507  678.89805
```
