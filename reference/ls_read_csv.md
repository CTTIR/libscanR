# Read a LIBS Spectrum from CSV (Convenience Wrapper)

Read a LIBS Spectrum from CSV (Convenience Wrapper)

## Usage

``` r
ls_read_csv(path, ...)
```

## Arguments

- path:

  Character. Path to CSV file.

- ...:

  Additional arguments passed to
  [`ls_read_spectrum()`](https://cttir.github.io/libscanR/reference/ls_read_spectrum.md).

## Value

A `libs_spectrum` object.

## Examples

``` r
tmp <- tempfile(fileext = ".csv")
wl <- seq(200, 900, length.out = 100)
utils::write.csv(data.frame(wavelength = wl,
                            intensity = exp(-((wl - 393)^2) / 2)),
                 tmp, row.names = FALSE)
spec <- ls_read_csv(tmp, verbose = FALSE)
unlink(tmp)
```
