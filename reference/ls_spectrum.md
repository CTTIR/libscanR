# Create a LIBS Spectrum Object

Constructs a `libs_spectrum` S3 object from a wavelength axis and one or
more intensity vectors (shots).

## Usage

``` r
ls_spectrum(wavelength, intensity, metadata = list(), baseline = NULL)
```

## Arguments

- wavelength:

  Numeric vector of wavelengths in nanometers. Must be sortable and
  contain no NA.

- intensity:

  Numeric vector (single shot) or matrix (multiple shots) of emission
  intensities. If matrix: rows = shots, columns = wavelength channels,
  `ncol(intensity)` must equal `length(wavelength)`.

- metadata:

  Named list of metadata (e.g. `sample_id`, `material`, `gate_delay_us`,
  `integration_time_us`, `laser_energy_mj`, `atmosphere`, `date`).
  Default [`list()`](https://rdrr.io/r/base/list.html).

- baseline:

  Optional numeric vector of baseline values corresponding to each
  wavelength channel (populated by
  [`ls_baseline()`](https://cttir.github.io/libscanR/reference/ls_baseline.md)).
  Default `NULL`.

## Value

An object of class `libs_spectrum`: a named list with elements
`wavelength`, `intensity` (matrix: shots x channels), `metadata`,
`baseline`, `n_shots`, `n_channels`, and `range_nm`.

## Examples

``` r
wl <- seq(200, 900, length.out = 512)
int <- exp(-((wl - 393)^2) / 2) + stats::rnorm(512, 0, 0.05)
spec <- ls_spectrum(wl, int, metadata = list(sample_id = "demo"))
print(spec)
#> <libs_spectrum>
#> • Range: 200-900 nm (512 channels)
#> • Shots: 1
#> • Sample: "demo"
#> • Baseline corrected: FALSE
```
