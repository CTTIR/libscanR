# Export a LIBS Dataset to a Directory

Writes each spectrum in a dataset as a separate CSV file, plus a
`sample_info.csv` metadata table. IDs must be unique portable filenames.
Existing output is left intact if `overwrite = FALSE`; if any target
exists, the whole export is skipped. All files are staged before
replacement, with rollback on ordinary write failures. Concurrent
writers and power-loss recovery are not supported.

## Usage

``` r
ls_export_spectra(dataset, dir, overwrite = FALSE)
```

## Arguments

- dataset:

  A `libs_dataset` object.

- dir:

  Character. Output directory (created if missing).

- overwrite:

  Logical. Overwrite existing files. Default `FALSE`.

## Value

Invisibly returns `dir`.

## Examples

``` r
ds <- ls_example_data("tissue")[1:3]
tmp <- tempfile()
ls_export_spectra(ds, tmp)
list.files(tmp)
#> [1] "bone_01.csv"     "bone_02.csv"     "bone_03.csv"     "sample_info.csv"
unlink(tmp, recursive = TRUE)
```
