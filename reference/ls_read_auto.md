# Auto-Detect and Read LIBS Data

Attempts to identify the file format (generic CSV, SciAps, Applied
Spectra) and dispatches to the correct reader. When `path` is a
directory, delegates to
[`ls_read_dir()`](https://cttir.github.io/libscanR/reference/ls_read_dir.md).

## Usage

``` r
ls_read_auto(path, verbose = TRUE)
```

## Arguments

- path:

  Character. Path to spectrum file or directory.

- verbose:

  Logical. Default `TRUE`.

## Value

A `libs_spectrum` or `libs_dataset` object.

## Examples

``` r
tmp <- tempfile(fileext = ".csv")
utils::write.csv(data.frame(wavelength = seq(200, 300, 1),
                            intensity = 1:101),
                 tmp, row.names = FALSE)
spec <- ls_read_auto(tmp, verbose = FALSE)
unlink(tmp)
```
