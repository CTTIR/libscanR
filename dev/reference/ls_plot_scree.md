# Plot PCA Variance (Scree Plot)

Plot PCA Variance (Scree Plot)

## Usage

``` r
ls_plot_scree(pca)
```

## Arguments

- pca:

  A `libs_pca` object.

## Value

A ggplot2 object.

## Examples

``` r
ds <- ls_example_data("tissue")
pca <- ls_pca(ds, n_components = 6)
ls_plot_scree(pca)
```
