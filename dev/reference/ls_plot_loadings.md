# Plot PCA Loadings

Plots the loadings for a selected principal component across the full
wavelength axis, optionally annotating the top contributing channels.

## Usage

``` r
ls_plot_loadings(pca, pc = 1, n_top = 10)
```

## Arguments

- pca:

  A `libs_pca` object.

- pc:

  Integer. Which PC's loadings to show. Default 1.

- n_top:

  Integer. Number of top-absolute contributors to annotate. Default 10.

## Value

A ggplot2 object.

## Examples

``` r
ds <- ls_example_data("tissue")
pca <- ls_pca(ds, n_components = 4)
ls_plot_loadings(pca, pc = 1, n_top = 5)
```
