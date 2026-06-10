# Overlay Multiple Spectra

Plots multiple spectra on the same axes, optionally colored by a
grouping variable.

## Usage

``` r
ls_plot_overlay(dataset, color_by = NULL, normalize = FALSE, alpha = 0.5)
```

## Arguments

- dataset:

  A
  [`ls_dataset()`](https://cttir.github.io/libscanR/reference/ls_dataset.md)
  object.

- color_by:

  Character. Column in `sample_info` for color mapping. Default `NULL`.

- normalize:

  Logical. Normalize each spectrum to `[0, 1]`. Default `FALSE`.

- alpha:

  Numeric. Line alpha. Default 0.5.

## Value

A ggplot2 object.

## Examples

``` r
ds <- ls_example_data("tissue")
ls_plot_overlay(ds[1:10], color_by = "tissue")
```
