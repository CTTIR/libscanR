# Plot PCA Scores

Plot PCA Scores

## Usage

``` r
ls_plot_pca(pca, pc_x = 1, pc_y = 2, color_by = NULL, ellipses = TRUE)
```

## Arguments

- pca:

  A `libs_pca` object from
  [`ls_pca()`](https://cttir.github.io/libscanR/dev/reference/ls_pca.md).

- pc_x:

  Integer. PC for x-axis. Default 1.

- pc_y:

  Integer. PC for y-axis. Default 2.

- color_by:

  Character. Sample-info column. Numeric values use a continuous colour
  scale; other values define discrete groups. Default `NULL`.

- ellipses:

  Logical. Draw nominal 95% normal-theory data ellipses for discrete
  groups with at least four non-collinear points. They describe score
  dispersion, not confidence intervals for a group mean. Default `TRUE`.

## Value

A ggplot2 object.

## Examples

``` r
ds <- ls_example_data("tissue")
pca <- ls_pca(ds, n_components = 4)
ls_plot_pca(pca, color_by = "tissue")
```
