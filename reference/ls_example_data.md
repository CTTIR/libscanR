# Generate Example LIBS Dataset

Creates a synthetic `libs_dataset` suitable for demonstrating package
features without an atomic reference download. All scenarios use
explicit fictional peaks from
[`ls_demo_peaks()`](https://cttir.github.io/libscanR/reference/ls_demo_peaks.md);
component names and tissue labels are teaching labels, not measured
concentrations or biological ground truth. Scenarios:

## Usage

``` r
ls_example_data(
  scenario = c("tissue", "calibration", "spatial", "all"),
  seed = 42,
  n_channels = 1024
)
```

## Arguments

- scenario:

  Character. One of `"tissue"`, `"calibration"`, `"spatial"`, `"all"`.
  Default `"tissue"`.

- seed:

  Integer. Random seed. Default 42.

- n_channels:

  Integer. Number of spectral channels. Default 1024 (reduced from 2048
  for faster examples).

## Value

A `libs_dataset` object (or named list for `"all"`).

## Details

- `"tissue"` — 50 spectra from 5 tissue types (bone, liver, kidney,
  muscle, fat), 10 per type, with deliberately different synthetic
  profiles.

- `"calibration"` — 27 spectra of Ca standards (9 concentrations x 3
  replicates) with constant matrix (Na, K, Mg).

- `"spatial"` — 400 spectra on a 20x20 grid simulating a tissue
  cross-section with Ca/Fe gradients and a Zn-enriched hotspot.

- `"all"` — named list of the above.

## Examples

``` r
ds <- ls_example_data("tissue")
print(ds)
#> <libs_dataset>
#> • Spectra: 50
#> • Channels: 1024
#> • Range: 200-900 nm
#> • Groups: 5 (material)
```
