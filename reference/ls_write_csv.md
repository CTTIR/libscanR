# Write a LIBS Spectrum to CSV

Exports a `libs_spectrum` to a CSV file with a `wavelength_nm` column
plus one column per shot.

## Usage

``` r
ls_write_csv(x, path, include_metadata = TRUE)
```

## Arguments

- x:

  A `libs_spectrum` object.

- path:

  Character. Output file path.

- include_metadata:

  Logical. Prepend metadata as comment lines. Default `TRUE`. JSON
  comments preserve scalar values, arrays, nested lists, and the
  baseline. Named vectors become JSON objects (lists on import);
  R-specific classes and attributes are not preserved.

## Value

Invisibly returns `path`.

## Examples

``` r
spec <- ls_simulate_spectrum(seed = 1)
tmp <- tempfile(fileext = ".csv")
ls_write_csv(spec, tmp)
unlink(tmp)
```
