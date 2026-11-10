# Identify Peaks Against the NIST Line Database

Matches detected peaks to known atomic emission lines. Each peak is
assigned its nearest wavelength candidate from the user-configured
reference. No atomic reference is bundled; configure
[`ls_element_db()`](https://cttir.github.io/libscanR/reference/ls_element_db.md)
first. This is a candidate identification, not proof of elemental
presence or resolution of blended transitions. Check the measured
air/vacuum convention.

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
`nist_wavelength_nm`, `nist_aki`, `deviation_nm`, `confidence` (0-1),
`n_candidates`, and `wavelength_medium`. The legacy `confidence` name
denotes only `1 - abs(deviation_nm) / tolerance_nm`, not a probability.

## Examples

``` r
if (FALSE) { # !is.null(getOption("libscanR.element_db")) || nzchar(Sys.getenv("LIBSCANR_ELEMENT_DB"))
spec <- ls_simulate_spectrum(line_data = ls_demo_peaks(),
                             elements = c(Ca = 5000, Na = 1000), seed = 1)
pk <- ls_find_peaks(spec, snr_threshold = 5)
id <- ls_identify_peaks(pk, elements = c("Ca", "Na"))
head(id)
}
```
