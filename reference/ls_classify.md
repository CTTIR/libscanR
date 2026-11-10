# Classify Unknown Spectra

Applies a trained classifier (from
[`ls_plsda()`](https://cttir.github.io/libscanR/reference/ls_plsda.md)
or
[`ls_train_classifier()`](https://cttir.github.io/libscanR/reference/ls_train_classifier.md))
to new spectra.

## Usage

``` r
ls_classify(model, new_data)
```

## Arguments

- model:

  A `libs_plsda` or `libs_classifier` object.

- new_data:

  A
  [`ls_dataset()`](https://cttir.github.io/libscanR/reference/ls_dataset.md)
  of unknown spectra.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns `sample_id`, `predicted_class`, and `score` for PLS-DA (an
unbounded discriminant score, not a probability), or `probability` for
SVM/RF. The wavelength axis and ordered preprocessing must match the
fitted contract. Legacy models without this contract must be refitted
before prediction.

## Examples

``` r
ds <- ls_example_data("tissue")
# \donttest{
if (requireNamespace("e1071", quietly = TRUE)) {
  clf <- ls_train_classifier(ds[1:30], "tissue", method = "svm")
  ls_classify(clf, ds[31:50])
}
#> # A tibble: 20 × 3
#>    sample_id predicted_class probability
#>    <chr>     <chr>                 <dbl>
#>  1 muscle_01 liver                 0.538
#>  2 muscle_02 liver                 0.499
#>  3 muscle_03 kidney                0.396
#>  4 muscle_04 liver                 0.582
#>  5 muscle_05 liver                 0.597
#>  6 muscle_06 liver                 0.603
#>  7 muscle_07 kidney                0.403
#>  8 muscle_08 kidney                0.397
#>  9 muscle_09 liver                 0.427
#> 10 muscle_10 liver                 0.546
#> 11 fat_01    bone                  0.429
#> 12 fat_02    liver                 0.585
#> 13 fat_03    liver                 0.551
#> 14 fat_04    liver                 0.594
#> 15 fat_05    kidney                0.399
#> 16 fat_06    liver                 0.536
#> 17 fat_07    kidney                0.403
#> 18 fat_08    kidney                0.403
#> 19 fat_09    kidney                0.397
#> 20 fat_10    bone                  0.422
# }
```
