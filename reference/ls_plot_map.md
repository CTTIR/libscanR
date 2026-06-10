# Plot an Elemental Map

Plot an Elemental Map

## Usage

``` r
ls_plot_map(map, color_scale = "viridis", title = NULL)
```

## Arguments

- map:

  A `libs_map` object from
  [`ls_build_map()`](https://cttir.github.io/libscanR/reference/ls_build_map.md).

- color_scale:

  Character. `"viridis"`, `"magma"`, `"plasma"`, `"inferno"`, `"hot"`,
  `"jet"`. Default `"viridis"`.

- title:

  Character. Plot title. Default: element symbol.

## Value

A ggplot2 object.

## Examples

``` r
ds <- ls_example_data("spatial")
m <- ls_build_map(ds, "Ca", 393.37)
ls_plot_map(m)
```
