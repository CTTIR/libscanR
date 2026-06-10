# Plot an Element Map (alias)

Convenience alias for
[`ls_plot_map()`](https://cttir.github.io/libscanR/reference/ls_plot_map.md).

## Usage

``` r
ls_plot_element_map(map, ...)
```

## Arguments

- map:

  A `libs_map` object.

- ...:

  Passed to
  [`ls_plot_map()`](https://cttir.github.io/libscanR/reference/ls_plot_map.md).

## Value

A ggplot2 object.

## Examples

``` r
ds <- ls_example_data("spatial")
ls_plot_element_map(ls_build_map(ds, "Ca", 393.37))
```
