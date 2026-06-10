# PLS-DA Classification

Partial Least Squares Discriminant Analysis for class prediction.

## Usage

``` r
ls_plsda(dataset, grouping, n_components = 5, validation = "CV")
```

## Arguments

- dataset:

  A
  [`ls_dataset()`](https://cttir.github.io/libscanR/reference/ls_dataset.md)
  object.

- grouping:

  Character. Column name in `sample_info` with class labels.

- n_components:

  Integer. Number of PLS latent variables. Default 5.

- validation:

  Character. `"CV"` (10-fold), `"LOO"`, or `"none"`. Default `"CV"`.

## Value

An S3 object of class `libs_plsda` with elements `model`, `predictions`
(tibble with predicted/observed class), `confusion_matrix`, `accuracy`,
`class_labels`, `n_components`, `sample_info`.

## Examples

``` r
ds <- ls_example_data("tissue")
# \donttest{
if (requireNamespace("pls", quietly = TRUE)) {
  plsda <- ls_plsda(ds, "tissue", n_components = 3, validation = "none")
  plsda$accuracy
}
#> [1] 0.48
# }
```
