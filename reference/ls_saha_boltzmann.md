# Calibration-Free LIBS via Saha-Boltzmann

Implements the CF-LIBS method for semi-quantitative analysis without
reference standards. Uses the Boltzmann plot method to estimate plasma
temperature and then relative elemental concentrations from line
intensities. Electron density is provided as an input or assumed.

## Usage

``` r
ls_saha_boltzmann(
  x,
  elements,
  lines_nm,
  electron_density = 1e+17,
  window_nm = 0.5,
  verbose = TRUE
)
```

## Arguments

- x:

  A
  [`ls_spectrum()`](https://cttir.github.io/libscanR/reference/ls_spectrum.md)
  object (ideally baseline-corrected).

- elements:

  Character vector. Elements to quantify.

- lines_nm:

  Named list. Emission lines per element for the Boltzmann plot, e.g.
  `list(Ca = c(393.37, 396.85, 422.67))`.

- electron_density:

  Numeric. Assumed electron density (cm^-3). Default `1e17`.

- window_nm:

  Numeric. Integration window per line. Default 0.5.

- verbose:

  Logical. Default `TRUE`.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns `element`, `temperature_k`, `concentration_rel` (relative
mole fraction, sum normalized to 1), `electron_density`, `n_lines`
(lines used), `r_squared` (Boltzmann fit).

## Examples

``` r
spec <- ls_simulate_spectrum(
  elements = c(Ca = 5000, Fe = 200, Na = 1000), seed = 2)
spec <- ls_baseline(spec)
ls_saha_boltzmann(spec,
  elements = c("Ca", "Fe"),
  lines_nm = list(Ca = c(422.673, 445.478, 487.813),
                  Fe = c(371.994, 404.581, 438.354)))
#> # A tibble: 2 × 6
#>   element temperature_k concentration_rel electron_density n_lines r_squared
#>   <chr>           <dbl>             <dbl>            <dbl>   <int>     <dbl>
#> 1 Ca            -65656.         0.0000425             1e17       3     0.449
#> 2 Fe              4378.         1.000                 1e17       3     0.907
```
