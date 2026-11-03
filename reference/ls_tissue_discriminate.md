# Tissue Discrimination Analysis

Identifies emission channels that best discriminate two tissue types via
per-wavelength t-tests with Benjamini-Hochberg FDR correction, plus log2
fold-change. Optionally matches significant channels to NIST elements.

## Usage

``` r
ls_tissue_discriminate(
  dataset,
  group_col,
  group_a,
  group_b,
  method = "t_test",
  tolerance_nm = 0.2
)
```

## Arguments

- dataset:

  A
  [`ls_dataset()`](https://cttir.github.io/libscanR/reference/ls_dataset.md)
  with tissue labels.

- group_col:

  Character. Label column in `sample_info`.

- group_a:

  Character. First group label.

- group_b:

  Character. Second group label.

- method:

  Character. `"t_test"` (default) or `"fold_change"`.

- tolerance_nm:

  Numeric. Matching tolerance when annotating elements. Default 0.2.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns `wavelength_nm`, `mean_a`, `mean_b`, `p_value`,
`fold_change`, `fdr`, `significant`, `element`.

## Examples

``` r
ds <- ls_example_data("tissue")
head(ls_tissue_discriminate(ds, "tissue", "bone", "muscle"))
#> # A tibble: 6 × 8
#>   wavelength_nm mean_a mean_b  p_value fold_change      fdr significant element
#>           <dbl>  <dbl>  <dbl>    <dbl>       <dbl>    <dbl> <lgl>       <chr>  
#> 1          866.   48.8   32.1 1.43e-13       0.588 1.46e-10 FALSE       NA     
#> 2          716.   63.0   41.7 1.10e-11       0.583 5.63e- 9 FALSE       NA     
#> 3          422.  491.    69.0 5.51e- 9       2.81  2.26e- 7 TRUE        NA     
#> 4          423.  460.    69.6 3.85e- 9       2.71  2.26e- 7 TRUE        NA     
#> 5          488.  352.    62.0 5.84e- 9       2.49  2.26e- 7 TRUE        NA     
#> 6          487.  327.    61.9 5.62e- 9       2.38  2.26e- 7 TRUE        NA     
```
