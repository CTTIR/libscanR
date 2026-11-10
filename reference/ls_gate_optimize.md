# Gate Delay Optimization

Analyzes SNR and signal-to-background ratios across spectra acquired at
different gate delays to recommend optimal timing for a target line.

## Usage

``` r
ls_gate_optimize(spectra, element, line_nm, window_nm = 1)
```

## Arguments

- spectra:

  List of
  [`ls_spectrum()`](https://cttir.github.io/libscanR/reference/ls_spectrum.md)
  objects. Each spectrum's metadata should contain `gate_delay_us`.

- element:

  Character. Target element symbol.

- line_nm:

  Numeric. Target emission line wavelength (nm).

- window_nm:

  Numeric. Window around the line. Default 1.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns `gate_delay_us`, `snr`, `sbr`, `peak_intensity`, with
attribute `"recommended"` giving the row index of the highest SNR.

## Examples

``` r
specs <- lapply(c(0.5, 1, 2, 5, 10), function(g) {
  s <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = round(g * 10))
  s$metadata$gate_delay_us <- g
  s
})
ls_gate_optimize(specs, "Ca", 393.37)
#> # A tibble: 5 × 4
#>   gate_delay_us   snr   sbr peak_intensity
#>           <dbl> <dbl> <dbl>          <dbl>
#> 1           0.5  7.63  1.07           75.0
#> 2           1    5.56  1.06           80.0
#> 3           2    6.06  1.06           78.8
#> 4           5    7.24  1.06           79.3
#> 5          10    8.22  1.07           76.0
```
