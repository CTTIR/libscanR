# Read Applied Spectra / Aurora Data

Parses output from Applied Spectra J200 and Aurora LIBS systems. Applied
Spectra files commonly have wavelength in the first column and shots in
subsequent columns, optionally with a few header lines.

## Usage

``` r
ls_read_aurora(path, verbose = TRUE)
```

## Arguments

- path:

  Character. Path to export file (.csv or .asc).

- verbose:

  Logical. Default `TRUE`.

## Value

A `libs_spectrum` object.

## Examples

``` r
tmp <- tempfile(fileext = ".csv")
writeLines(c(
  "Applied Spectra J200",
  "Model,J200",
  "wl,shot1,shot2",
  "200.0,50,52",
  "200.5,55,58",
  "201.0,52,50"
), tmp)
spec <- ls_read_aurora(tmp, verbose = FALSE)
unlink(tmp)
```
