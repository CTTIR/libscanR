# Build a Spatial Elemental Map

Constructs a spatial map from LIBS line-scan or raster-scan data. The
dataset's `sample_info` must include `x_pos` and `y_pos` columns.

## Usage

``` r
ls_build_map(dataset, element, line_nm, calibration = NULL, window_nm = 1)
```

## Arguments

- dataset:

  A
  [`ls_dataset()`](https://cttir.github.io/libscanR/reference/ls_dataset.md)
  object with spatial coordinates.

- element:

  Character. Element label (for metadata).

- line_nm:

  Numeric. Emission line wavelength (nm).

- calibration:

  Optional
  [`ls_calibration()`](https://cttir.github.io/libscanR/reference/ls_calibration.md).
  If provided, intensities are converted to concentration. Default
  `NULL`.

- window_nm:

  Numeric. Peak integration window. Default 1.

## Value

A list with S3 class `libs_map` containing `x`, `y`, `values`,
`element`, `line_nm`, `unit`, and a rasterized `grid` matrix when the
points form a regular grid.

## Examples

``` r
ds <- ls_example_data("spatial")
m <- ls_build_map(ds, "Ca", 393.37)
dim(m$grid)
#> [1] 20 20
```
