# Find Emission Peaks

Detects peaks in a LIBS spectrum using local maxima detection with
prominence and signal-to-noise filtering.

## Usage

``` r
ls_find_peaks(
  x,
  snr_threshold = 3,
  min_prominence = 0.01,
  min_distance_nm = 0.5
)
```

## Arguments

- x:

  A
  [`ls_spectrum()`](https://cttir.github.io/libscanR/reference/ls_spectrum.md)
  object.

- snr_threshold:

  Numeric. Minimum signal-to-noise ratio. Default 3.

- min_prominence:

  Numeric. Minimum peak prominence as a fraction of maximum intensity
  (0-1). Default 0.01.

- min_distance_nm:

  Numeric. Minimum distance between peaks (nm). Default 0.5.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns `wavelength_nm`, `intensity`, `snr`, `prominence`,
`fwhm_nm`, `area`, sorted by intensity descending.

## Examples

``` r
spec <- ls_simulate_spectrum(elements = c(Ca = 5000, Na = 1000), seed = 1)
peaks <- ls_find_peaks(spec, snr_threshold = 5)
head(peaks)
#> # A tibble: 6 × 6
#>   wavelength_nm intensity   snr prominence fwhm_nm  area
#>           <dbl>     <dbl> <dbl>      <dbl>   <dbl> <dbl>
#> 1          240.      98.7  67.4       9.70      NA     0
#> 2          202.      97.1  65.1       2.03      NA     0
#> 3          206.      95.7  63.0       1.56      NA     0
#> 4          208.      95.7  63.0       1.04      NA     0
#> 5          205.      95.4  62.6       1.23      NA     0
#> 6          212.      94.9  61.8       1.59      NA     0
```
