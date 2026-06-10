# Read All Spectra from a Directory

Batch-imports spectrum files from a directory into a `libs_dataset`.

## Usage

``` r
ls_read_dir(
  dir,
  pattern = "\\.(csv|tsv|txt)$",
  recursive = FALSE,
  sample_info = NULL,
  ...
)
```

## Arguments

- dir:

  Character. Directory path.

- pattern:

  Character. File pattern (regex). Default `"\\.(csv|tsv|txt)$"`.

- recursive:

  Logical. Recurse into subdirectories. Default `FALSE`.

- sample_info:

  data.frame/tibble. Optional sample metadata table. Must have a
  `sample_id` column matching (or being a subset of) the filenames
  without extension. Default `NULL`.

- ...:

  Additional arguments passed to
  [`ls_read_spectrum()`](https://cttir.github.io/libscanR/reference/ls_read_spectrum.md).

## Value

A `libs_dataset` object.

## Examples

``` r
dir <- tempfile()
dir.create(dir)
for (i in 1:3) {
  wl <- seq(200, 900, length.out = 100)
  int <- exp(-((wl - 393)^2) / 2) + stats::rnorm(100, 0, 0.01)
  utils::write.csv(data.frame(w = wl, i = int),
                   file.path(dir, paste0("s", i, ".csv")),
                   row.names = FALSE)
}
ds <- ls_read_dir(dir, verbose = FALSE)
unlink(dir, recursive = TRUE)
```
