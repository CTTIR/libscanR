# Launch the libscanR Shiny Application

Starts an interactive Shiny application for exploring, preprocessing,
and analyzing LIBS spectral data. The app provides six tabs: Import,
Preprocessing, Peaks, Calibration, Chemometrics, and Export.

## Usage

``` r
ls_run_app(data = NULL, port = NULL, launch.browser = TRUE)
```

## Arguments

- data:

  Optional. A
  [`ls_spectrum()`](https://cttir.github.io/libscanR/reference/ls_spectrum.md),
  [`ls_dataset()`](https://cttir.github.io/libscanR/reference/ls_dataset.md),
  or file path to preload. Default `NULL` (start with upload interface).

- port:

  Integer. Port for the app. Default `NULL` (auto-select).

- launch.browser:

  Logical. Open browser on launch. Default `TRUE`.

## Value

Invisible `NULL`. Launches a Shiny application as a side effect.

## Examples

``` r
# \donttest{
if (interactive()) {
  ls_run_app()
}
# }
```
