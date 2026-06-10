# Create a LIBS Dataset

Constructs a `libs_dataset`: a collection of
[`ls_spectrum()`](https://cttir.github.io/libscanR/reference/ls_spectrum.md)
objects sharing a common wavelength axis, plus a sample-info table.

## Usage

``` r
ls_dataset(spectra, sample_info = NULL)
```

## Arguments

- spectra:

  List of `libs_spectrum` objects. All must share the same wavelength
  axis (channels and values within 0.1 nm tolerance).

- sample_info:

  Optional data.frame or tibble with one row per spectrum. Must contain
  column `sample_id` matching `metadata$sample_id` in each spectrum.
  Additional columns (e.g. `material`, `group`, `concentration`,
  `x_pos`, `y_pos`) are optional. If NULL, built from spectrum metadata.

## Value

A `libs_dataset` S3 object.

## Examples

``` r
specs <- lapply(1:3, function(i) {
  ls_simulate_spectrum(elements = c(Ca = 1000 * i, Na = 500), seed = i)
})
specs <- Map(function(s, id) {
  s$metadata$sample_id <- paste0("s", id)
  s
}, specs, seq_along(specs))
ds <- ls_dataset(specs)
print(ds)
#> <libs_dataset>
#> • Spectra: 3
#> • Channels: 2048
#> • Range: 200-900 nm
#> • Groups: 1 (material)
```
