# Read SciAps LIBS Data

Parses output files from SciAps handheld LIBS analyzers (Z-series). The
SciAps export format typically includes metadata lines preceded by `#`
or a keyword header, followed by a wavelength/intensity table.

## Usage

``` r
ls_read_sciaps(path, verbose = TRUE)
```

## Arguments

- path:

  Character. Path to SciAps export file.

- verbose:

  Logical. Emit messages. Default `TRUE`.

## Value

A `libs_spectrum` object with SciAps-specific metadata.

## Examples

``` r
# See vignette("getting-started") for realistic usage; this parser
# is best exercised against actual SciAps export files.
tmp <- tempfile(fileext = ".csv")
writeLines(c(
  "# SciAps Z-903",
  "# Serial: 12345",
  "# Gate Delay (us): 2.5",
  "wavelength,intensity",
  "200.0,50",
  "200.5,55",
  "201.0,52"
), tmp)
spec <- ls_read_sciaps(tmp, verbose = FALSE)
unlink(tmp)
```
