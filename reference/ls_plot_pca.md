# Plot PCA Scores

Plot PCA Scores

## Usage

``` r
ls_plot_pca(pca, pc_x = 1, pc_y = 2, color_by = NULL, ellipses = TRUE)
```

## Arguments

- pca:

  A `libs_pca` object from
  [`ls_pca()`](https://cttir.github.io/libscanR/reference/ls_pca.md).

- pc_x:

  Integer. PC for x-axis. Default 1.

- pc_y:

  Integer. PC for y-axis. Default 2.

- color_by:

  Character. Grouping variable. Default `NULL`.

- ellipses:

  Logical. Draw 95% confidence ellipses per group. Default `TRUE`.

## Value

A ggplot2 object.

## Examples

``` r
ds <- ls_example_data("tissue")
pca <- ls_pca(ds, n_components = 4)
ls_plot_pca(pca, color_by = "tissue")
```
