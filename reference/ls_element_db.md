# Read a User-Supplied Atomic Line Reference

Reads a local CSV or RDS table supplied by the user. No atomic reference
compilation is bundled and this function does not access the network.
Configure a file with `options(libscanR.element_db = "/path/lines.csv")`
or the environment variable `LIBSCANR_ELEMENT_DB`. An explicit `path`
takes precedence over the option, which takes precedence over the
variable.

## Usage

``` r
ls_element_db(
  elements = NULL,
  range_nm = c(190, 900),
  min_aki = 0,
  ionization = c(1L, 2L),
  persistent_only = FALSE,
  path = NULL
)
```

## Arguments

- elements:

  Character vector of element symbols, or `NULL` for all.

- range_nm:

  Two ordered finite wavelength limits, or `NULL` for all.

- min_aki:

  Minimum transition probability in units of 10^8 s^-1. Missing rates
  are excluded only when this is positive.

- ionization:

  Ionization states: 1 = neutral, 2 = singly ionized, or `NULL` for all
  supplied positive integer stages.

- persistent_only:

  Keep only rows explicitly marked `persistent`.

- path:

  Local CSV/RDS file. Default `NULL` uses the configured path.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
retaining the reference columns. Physical fields required by
[`ls_saha_boltzmann()`](https://cttir.github.io/libscanR/reference/ls_saha_boltzmann.md)
must be supplied and independently checked; loading a reference does not
establish its scientific validity or reuse rights.

## Details

The table must contain `element`, `ionization`, `wavelength_nm`, `aki`
(transition probability in units of 10^8 s^-1), `wavelength_medium`
(`"air"` or `"vacuum"`) and a nonempty `source` attribution per row.
Missing transition rates remain missing. Optional `ei_ev`, `ek_ev` and
`persistent` columns default to missing energies and `FALSE`; no
persistent line designation is inferred. Other columns and provenance
are retained. The installed package provides `scripts/import_nist.py`
for converting a separately downloaded NIST ASD CSV; see the README for
exact settings.

## Examples

``` r
# After downloading and importing a reference as described in the README:
# options(libscanR.element_db = "local-data/atomic-lines.csv")
# ls_element_db(elements = "Ca")
```
