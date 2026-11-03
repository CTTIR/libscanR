# Plot Multi-Element Map Panel

Plots multiple elemental maps as a faceted panel.

## Usage

``` r
ls_plot_map_panel(maps, ncol = 3)
```

## Arguments

- maps:

  Named list of `libs_map` objects.

- ncol:

  Integer. Facet columns. Default 3.

## Value

A ggplot2 object.

## Examples

``` r
ds <- ls_example_data("spatial")
ms <- ls_map_elements(ds, c("Ca", "Fe", "Zn"),
                      c(Ca = 393.37, Fe = 371.99, Zn = 213.86))
ls_plot_map_panel(ms)
```
