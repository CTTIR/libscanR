# Overlay Multiple Spectra

Plots multiple spectra on the same axes, optionally coloured by a
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

  Character. Column in `sample_info` for colour mapping. Default `NULL`.

- normalize:

  Logical. Divide each spectrum by its positive maximum. Default
  `FALSE`.

- alpha:

  Numeric. Line alpha. Default 0.5.

## Value

A ggplot2 object.

## Examples

``` r
ds <- ls_example_data("tissue")
# Three spectra from each of the five fictional tissue labels
keep <- unlist(lapply(split(seq_len(length(ds)), ds$sample_info$tissue),
                      utils::head, 3))
ls_plot_overlay(ds[keep], color_by = "tissue")
```
