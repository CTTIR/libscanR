# PLS-DA Classification

Partial Least Squares Discriminant Analysis for class prediction.

## Usage

``` r
ls_plsda(dataset, grouping, n_components = 5, validation = "CV")
```

## Arguments

- dataset:

  A
  [`ls_dataset()`](https://cttir.github.io/libscanR/dev/reference/ls_dataset.md)
  object.

- grouping:

  Character. Column name in `sample_info` with class labels.

- n_components:

  Integer. Number of PLS latent variables. Default 5.

- validation:

  Character. `"CV"` (10-fold), `"LOO"`, or `"none"`. Default `"CV"`.
  Accuracy and predictions use held-out predictions for CV/LOO and
  fitted predictions only for `"none"`. Components are capped at the
  centered feature rank and training-sample bound of every fold. Every
  training fold must retain at least two classes. These sample-level
  folds do not establish patient/site-level generalization.

## Value

An S3 object of class `libs_plsda` with elements `model`, `predictions`
(tibble with predicted/observed class), `confusion_matrix`, `accuracy`,
`class_labels`, `n_components`, `sample_info`, `feature_contract`, and
`evaluation_basis` (`"cross_validation"`, `"leave_one_out"`, or
`"training"`).

## Examples

``` r
ds <- ls_example_data("tissue")
# \donttest{
if (requireNamespace("pls", quietly = TRUE)) {
  plsda <- ls_plsda(ds, "tissue", n_components = 3, validation = "none")
  plsda$accuracy
}
#> [1] 0.58
# }
```
