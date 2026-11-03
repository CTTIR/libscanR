# Read a LIBS Spectrum from File

Reads a single spectrum file. Supports CSV, TSV, and TXT formats where
columns represent wavelength and intensity.

## Usage

``` r
ls_read_spectrum(
  path,
  format = "auto",
  wavelength_col = 1,
  intensity_col = 2,
  skip = 0,
  metadata = list(),
  verbose = TRUE
)
```

## Arguments

- path:

  Character. Path to spectrum file.

- format:

  Character. One of `"auto"` (detect from extension), `"csv"`, `"tsv"`,
  `"txt"`. Default `"auto"`.

- wavelength_col:

  Column index or name for wavelength values. Default 1.

- intensity_col:

  Column index/indices or name(s) for intensity values. Multiple columns
  are interpreted as multiple shots. Default 2.

- skip:

  Integer. Header lines to skip before the data table. Default 0.

- metadata:

  Named list of additional metadata. Default
  [`list()`](https://rdrr.io/r/base/list.html).

- verbose:

  Logical. Emit import messages. Default `TRUE`.

## Value

A `libs_spectrum` object.

## Examples

``` r
tmp <- tempfile(fileext = ".csv")
wl <- seq(200, 900, length.out = 100)
int <- exp(-((wl - 393)^2) / 2)
utils::write.csv(data.frame(wavelength = wl, intensity = int),
                 tmp, row.names = FALSE)
spec <- ls_read_spectrum(tmp, verbose = FALSE)
unlink(tmp)
```
