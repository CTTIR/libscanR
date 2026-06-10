# Build Calibration Curve

Constructs a calibration model from standards with known concentrations.

## Usage

``` r
ls_calibrate(
  dataset,
  element,
  line_nm,
  concentrations,
  method = "univariate",
  internal_std_nm = NULL,
  window_nm = 1,
  pls_window_nm = NULL,
  n_components = 5,
  unit = "ppm",
  verbose = TRUE
)
```

## Arguments

- dataset:

  A
  [`ls_dataset()`](https://cttir.github.io/libscanR/reference/ls_dataset.md)
  containing standard spectra. Spectra order must correspond to
  `concentrations`.

- element:

  Character. Target element symbol.

- line_nm:

  Numeric. Emission line wavelength (nm).

- concentrations:

  Numeric vector of known concentrations, one per spectrum in `dataset`.

- method:

  Character. `"univariate"` (default), `"internal_std"`, `"pls"`, or
  `"cf_libs"`.

- internal_std_nm:

  Numeric. Internal standard line wavelength, required for
  `method = "internal_std"`.

- window_nm:

  Numeric. Peak integration window. Default 1.

- pls_window_nm:

  Numeric vector of length 2. Spectral window for PLS. Default
  `c(line_nm - 5, line_nm + 5)`.

- n_components:

  Integer. Number of PLS components. Default 5.

- unit:

  Character. Concentration unit. Default `"ppm"`.

- verbose:

  Logical. Default `TRUE`.

## Value

A
[`ls_calibration()`](https://cttir.github.io/libscanR/reference/ls_calibration.md)
object.

## Examples

``` r
ds <- ls_example_data("calibration")
conc <- ds$sample_info$concentration
cal <- ls_calibrate(ds, "Ca", 393.37, conc, verbose = FALSE)
print(cal)
#> <libs_calibration>
#> • Element: "Ca"
#> • Line: 393.37 nm
#> • Method: "univariate"
#> • Unit: "ppm"
#> • Standards: 27
#> • R-squared: 0.9497
#> • LOD: 3.96 ppm
#> • LOQ: 13.2 ppm
```
