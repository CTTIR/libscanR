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
  s <- ls_simulate_spectrum(seed = round(g * 10))
  s$metadata$gate_delay_us <- g
  s
})
ls_gate_optimize(specs, "Ca", 393.37)
#> # A tibble: 5 × 4
#>   gate_delay_us   snr   sbr peak_intensity
#>           <dbl> <dbl> <dbl>          <dbl>
#> 1           0.5 10.6   1.10           77.1
#> 2           1    8.09  1.09           82.3
#> 3           2    9.48  1.09           81.0
#> 4           5   10.6   1.09           81.5
#> 5          10   10.8   1.10           78.0
```
