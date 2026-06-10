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
#>   wavelength_nm mean_a mean_b   p_value fold_change      fdr significant element
#>           <dbl>  <dbl>  <dbl>     <dbl>       <dbl>    <dbl> <lgl>       <chr>  
#> 1          719.   78.4   41.7 3.18 e-10       0.894  1.84e-7 FALSE       NA     
#> 2          432.   87.0   68.4 3.59 e-10       0.343  1.84e-7 FALSE       NA     
#> 3          647.  121.    47.3 9.08 e-10       1.34   2.56e-7 TRUE        NA     
#> 4          866.   47.4   32.5 1.000e- 9       0.532  2.56e-7 FALSE       NA     
#> 5          715.  101.    41.8 2.02 e- 9       1.25   3.04e-7 TRUE        NA     
#> 6          656.  110.    46.3 1.96 e- 9       1.23   3.04e-7 TRUE        H      
```
