# Build Maps for Multiple Elements

Build Maps for Multiple Elements

## Usage

``` r
ls_map_elements(
  dataset,
  elements,
  lines_nm,
  calibrations = NULL,
  window_nm = 1
)
```

## Arguments

- dataset:

  A
  [`ls_dataset()`](https://cttir.github.io/libscanR/reference/ls_dataset.md)
  object with spatial coordinates.

- elements:

  Character vector. Elements to map.

- lines_nm:

  Named numeric vector: wavelength per element (e.g.
  `c(Ca = 393.37, Fe = 371.99)`).

- calibrations:

  Named list of
  [`ls_calibration()`](https://cttir.github.io/libscanR/reference/ls_calibration.md)
  objects. Default `NULL`.

- window_nm:

  Numeric. Integration window. Default 1.

## Value

A named list of `libs_map` objects.

## Examples

``` r
ds <- ls_example_data("spatial")
ls_map_elements(ds, c("Ca", "Fe"),
                c(Ca = 393.37, Fe = 371.99))
#> $Ca
#> <libs_map>
#> • Element: "Ca"
#> • Line: 393.37 nm
#> • Points: 400
#> • Range: 0-13 a.u.
#> • Grid: 20x20
#> 
#> $Fe
#> <libs_map>
#> • Element: "Fe"
#> • Line: 371.99 nm
#> • Points: 400
#> • Range: 0-5.43 a.u.
#> • Grid: 20x20
#> 
```
