# Plot a LIBS Spectrum

Generic spectrum plotter. Returns a ggplot2 object.

## Usage

``` r
ls_plot_spectrum(
  x,
  show_peaks = FALSE,
  show_elements = NULL,
  normalize = FALSE,
  snr_threshold = 5,
  ...
)
```

## Arguments

- x:

  A
  [`ls_spectrum()`](https://cttir.github.io/libscanR/dev/reference/ls_spectrum.md)
  object.

- show_peaks:

  Logical. Annotate detected peaks. Default `FALSE`.

- show_elements:

  Character vector of element symbols to highlight as dashed vertical
  lines from the configured reference. All matching rows in the
  displayed range are used; no persistent-line status is inferred.
  Default `NULL`.

- normalize:

  Logical. Divide intensity by its positive maximum before plotting.
  Default `FALSE`.

- snr_threshold:

  Numeric. SNR threshold for peak annotation when `show_peaks = TRUE`.
  Default 5.

- ...:

  Additional arguments (currently unused).

## Value

A ggplot2 object.

## Examples

``` r
spec <- ls_simulate_spectrum(line_data = ls_demo_peaks(), seed = 1)
ls_plot_spectrum(spec)

# Element overlays require a configured reference; see ls_element_db().
```
