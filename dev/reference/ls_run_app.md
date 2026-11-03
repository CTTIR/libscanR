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
  [`ls_spectrum()`](https://cttir.github.io/libscanR/dev/reference/ls_spectrum.md),
  [`ls_dataset()`](https://cttir.github.io/libscanR/dev/reference/ls_dataset.md),
  or file path to preload. Objects and files are validated before
  starting the app. Default `NULL` (start with upload interface).

- port:

  Integer. Port for the app. Default `NULL` (auto-select).

- launch.browser:

  Logical. Open browser on launch. Default `TRUE`.

## Value

Invisible `NULL`. Launches a Shiny application as a side effect.

## Details

Upload batches are admitted together: invalid files leave the previously
loaded data intact. Original upload names identify their source. New
data and successful preprocessing invalidate downstream analysis
results. Preprocessing controls take effect only after Apply; a failed
operation retains the last successful data, and Reset restores raw data.

The complete ZIP download contains one CSV per spectrum and, for a
dataset, `sample_info.csv`. Spectrum CSV files retain all shots,
baseline and supported metadata through
[`ls_write_csv()`](https://cttir.github.io/libscanR/dev/reference/ls_write_csv.md).
ZIP creation requires an external `zip` command on `PATH` (or configured
through `R_ZIPCMD`), including on Windows. The separate wide dataset CSV
contains mean intensities only. Calibration CSV files summarize figures
of merit rather than storing reusable prediction models. Load a labelled
[`ls_dataset()`](https://cttir.github.io/libscanR/dev/reference/ls_dataset.md)
through `data` for analyses requiring concentration or class columns in
`sample_info`.

Example datasets use explicitly fictional teaching peaks and
concentrations, not an atomic reference or experimental measurements.
Peak detection and raw plots work without a reference. Optional element
annotations require a user-supplied file configured for
[`ls_element_db()`](https://cttir.github.io/libscanR/dev/reference/ls_element_db.md);
missing or invalid references leave raw detections available and report
the annotation error. Peak and calibration CSVs carry
`data_origin = "explicit_synthetic_peaks"` for wholly fictional inputs;
mixed calibration inputs carry `"includes_explicit_synthetic_peaks"`.
Peak exports follow the first spectrum actually used for detection.

The previous application data option is restored when the app stops or
startup fails. Each browser session keeps its own working data and
results.

## Examples

``` r
# \donttest{
if (interactive()) {
  ls_run_app()
}
# }
```
