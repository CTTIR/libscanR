# Identify Peaks Against the NIST Line Database

Matches detected peaks to known atomic emission lines. Each peak is
assigned its best-scoring candidate from the curated NIST database.

## Usage

``` r
ls_identify_peaks(
  peaks,
  elements = NULL,
  tolerance_nm = 0.2,
  ionization = c(1L, 2L)
)
```

## Arguments

- peaks:

  A tibble from
  [`ls_find_peaks()`](https://cttir.github.io/libscanR/reference/ls_find_peaks.md).

- elements:

  Character vector. Restrict search. Default `NULL` = all.

- tolerance_nm:

  Numeric. Maximum wavelength deviation. Default 0.2.

- ionization:

  Integer vector of ionization states. Default `c(1L, 2L)`.

## Value

A tibble with all peak columns plus: `element`, `ionization`,
`nist_wavelength_nm`, `nist_aki`, `deviation_nm`, `confidence` (0-1).

## Examples

``` r
spec <- ls_simulate_spectrum(elements = c(Ca = 5000, Na = 1000), seed = 1)
pk <- ls_find_peaks(spec, snr_threshold = 5)
id <- ls_identify_peaks(pk, elements = c("Ca", "Na"))
head(id)
#> # A tibble: 6 × 12
#>   wavelength_nm intensity   snr prominence fwhm_nm  area element ionization
#>           <dbl>     <dbl> <dbl>      <dbl>   <dbl> <dbl> <chr>        <int>
#> 1          240.      98.7  67.4       9.70      NA     0 Ca               1
#> 2          202.      97.1  65.1       2.03      NA     0 NA              NA
#> 3          206.      95.7  63.0       1.56      NA     0 NA              NA
#> 4          208.      95.7  63.0       1.04      NA     0 NA              NA
#> 5          205.      95.4  62.6       1.23      NA     0 NA              NA
#> 6          212.      94.9  61.8       1.59      NA     0 NA              NA
#> # ℹ 4 more variables: nist_wavelength_nm <dbl>, nist_aki <dbl>,
#> #   deviation_nm <dbl>, confidence <dbl>
```
