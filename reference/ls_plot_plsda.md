# Plot PLS-DA Results

Plot PLS-DA Results

## Usage

``` r
ls_plot_plsda(plsda, type = "scores")
```

## Arguments

- plsda:

  A `libs_plsda` object from
  [`ls_plsda()`](https://cttir.github.io/libscanR/reference/ls_plsda.md).

- type:

  Character. `"scores"` (LV1 vs LV2), `"confusion"` (heatmap), or
  `"vip"` (VIP scores spectrum). Default `"scores"`.

## Value

A ggplot2 object.

## Examples

``` r
ds <- ls_example_data("tissue")
# \donttest{
if (requireNamespace("pls", quietly = TRUE)) {
  plsda <- ls_plsda(ds, "tissue", n_components = 3, validation = "none")
  ls_plot_plsda(plsda, type = "scores")
}

# }
```
