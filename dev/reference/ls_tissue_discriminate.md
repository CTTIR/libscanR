# Tissue Discrimination Analysis

Identifies emission channels that best discriminate two tissue types via
per-wavelength t-tests with Benjamini-Hochberg FDR correction, plus log2
fold-change. Element annotations are nearest wavelength candidates, not
established elemental identities; `candidate_count` records ambiguity.
Without a configured atomic reference, statistical results remain
available, with missing element annotations and
`annotation_status = "reference_unavailable"`. A configured but
unreadable or invalid reference raises an error.

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
  [`ls_dataset()`](https://cttir.github.io/libscanR/dev/reference/ls_dataset.md)
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
#> # A tibble: 6 × 11
#>   wavelength_nm mean_a mean_b    p_value fold_change     fdr significant element
#>           <dbl>  <dbl>  <dbl>      <dbl>       <dbl>   <dbl> <lgl>       <chr>  
#> 1          394.   265.   73.0    6.55e-9       1.86  3.35e-6 TRUE        NA     
#> 2          393.   250.   72.7    4.20e-9       1.78  3.35e-6 TRUE        NA     
#> 3          394.   160.   72.3    1.27e-8       1.14  4.31e-6 TRUE        NA     
#> 4          392.   139.   73.0    1.69e-8       0.934 4.31e-6 FALSE       NA     
#> 5          214.   199.   99.2    1.71e-7       1.00  2.72e-5 TRUE        NA     
#> 6          213.   169.   98.5    1.86e-7       0.775 2.72e-5 FALSE       NA     
#> # ℹ 3 more variables: candidate_count <int>, matched_wavelength_nm <dbl>,
#> #   annotation_status <chr>
```
