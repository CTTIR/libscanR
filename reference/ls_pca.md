# Principal Component Analysis of LIBS Spectra

Performs PCA on the intensity matrix of a
[`ls_dataset()`](https://cttir.github.io/libscanR/reference/ls_dataset.md).

## Usage

``` r
ls_pca(dataset, n_components = 10, scale = TRUE, center = TRUE)
```

## Arguments

- dataset:

  A
  [`ls_dataset()`](https://cttir.github.io/libscanR/reference/ls_dataset.md)
  object.

- n_components:

  Integer. Number of PCs to retain. Default 10.

- scale:

  Logical. Scale variables to unit variance. Default `TRUE`.

- center:

  Logical. Center variables. Default `TRUE`.

## Value

A list with S3 class `libs_pca` containing: `scores` (matrix: spectra x
PCs), `loadings` (matrix: channels x PCs), `sdev`, `variance_explained`
(fraction), `cumulative_variance`, `wavelength`, `sample_info`,
`pca_obj`.

## Examples

``` r
ds <- ls_example_data("tissue")
pca <- ls_pca(ds, n_components = 5)
pca$variance_explained
#> [1] 0.51563826 0.14653577 0.04380068 0.04138021 0.04014311
```
