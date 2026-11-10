# Train a Classifier

Trains SVM or Random Forest on spectral intensity features.

## Usage

``` r
ls_train_classifier(dataset, grouping, method = "svm", ...)
```

## Arguments

- dataset:

  A
  [`ls_dataset()`](https://cttir.github.io/libscanR/reference/ls_dataset.md)
  with labelled samples.

- grouping:

  Character. Column name in `sample_info` with class labels.

- method:

  Character. `"svm"` or `"rf"`. Default `"svm"`.

- ...:

  Additional arguments passed to the underlying trainer.

## Value

An S3 object of class `libs_classifier`, including predictions, a square
confusion matrix, the fitted `feature_contract`, and `evaluation_basis`:
`"training"` for SVM or `"out_of_bag"` for RF. SVM evaluation uses the
same probability-based class decision as
[`ls_classify()`](https://cttir.github.io/libscanR/reference/ls_classify.md).
Training accuracy is not an independent estimate of generalization.

## Examples

``` r
ds <- ls_example_data("tissue")
# \donttest{
if (requireNamespace("e1071", quietly = TRUE)) {
  clf <- ls_train_classifier(ds, "tissue", method = "svm")
  clf$accuracy
}
#> [1] 0.5
# }
```
