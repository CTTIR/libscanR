# Tissue Classification via LIBS

Classifies tissue types based on LIBS spectral signatures. Implements
three methods:

- `"ratio"` — rule-based using canonical elemental ratios (Ca/Na, Fe/Na,
  Zn/Na, K/Na, C/Ca) derived from tissue biochemistry. No training data
  required.

- `"plsda"` — fits a PLS-DA model on the supplied labelled `reference`
  dataset and predicts class for `x`.

- `"svm"` — fits an SVM on `reference` and predicts class.

## Usage

``` r
ls_tissue_classify(
  x,
  method = "ratio",
  reference = NULL,
  group_col = "tissue",
  verbose = TRUE
)
```

## Arguments

- x:

  A
  [`ls_spectrum()`](https://cttir.github.io/libscanR/reference/ls_spectrum.md)
  or
  [`ls_dataset()`](https://cttir.github.io/libscanR/reference/ls_dataset.md)
  object (unknowns).

- method:

  Character. `"ratio"`, `"plsda"`, or `"svm"`. Default `"ratio"`.

- reference:

  A
  [`ls_dataset()`](https://cttir.github.io/libscanR/reference/ls_dataset.md)
  with labelled tissue reference spectra (needed for `"plsda"` and
  `"svm"`).

- group_col:

  Character. Column in reference `sample_info` with tissue labels.
  Default `"tissue"`.

- verbose:

  Logical. Default `TRUE`.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns `sample_id`, `predicted_tissue`, `confidence`.

## Examples

``` r
ds <- ls_example_data("tissue")
ls_tissue_classify(ds[1:3])
#> # A tibble: 3 × 3
#>   sample_id predicted_tissue confidence
#>   <chr>     <chr>                 <dbl>
#> 1 bone_01   bone                  0.999
#> 2 bone_02   bone                  1.000
#> 3 bone_03   bone                  1.000
```
