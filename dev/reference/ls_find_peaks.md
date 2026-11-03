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
  [`ls_spectrum()`](https://cttir.github.io/libscanR/dev/reference/ls_spectrum.md)
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
spec <- ls_simulate_spectrum(line_data = ls_demo_peaks(),
                             elements = c(Ca = 5000, Na = 1000), seed = 1)
peaks <- ls_find_peaks(spec, snr_threshold = 5)
head(peaks)
#> # A tibble: 6 × 6
#>   wavelength_nm intensity   snr prominence fwhm_nm  area
#>           <dbl>     <dbl> <dbl>      <dbl>   <dbl> <dbl>
#> 1          202.      97.1  67.6       1.99   2.18  1.05 
#> 2          206.      95.7  65.5       1.53   1.38  0    
#> 3          208.      95.6  65.4       1.02   0.466 0.275
#> 4          205.      95.4  65.1       1.21   0.628 0.262
#> 5          212.      94.9  64.2       1.56   0.653 0.301
#> 6          213.      94.8  64.1       1.28   1.08  0    
```
