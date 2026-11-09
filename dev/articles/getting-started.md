# Getting Started with libscanR

![libscanR logo](figures/logo.svg)![libscanR
logo](figures/logo-dark.svg)

``` r

library(libscanR)
```

## What is libscanR?

`libscanR` provides a vendor-agnostic pipeline for Laser-Induced
Breakdown Spectroscopy (LIBS) data, including import, preprocessing,
peak detection, calibration, quantification, chemometrics, spatial
mapping, and visualization. It includes explicitly fictional teaching
datasets. Atomic-line identification requires a separately downloaded,
user-configured reference; no NIST compilation is bundled. See the
README for local download/import configuration.

## Core data structures

`libscanR` defines three S3 classes:

- `libs_spectrum` — a single spectrum (possibly multi-shot).
- `libs_dataset` — a collection of spectra sharing a wavelength axis.
- `libs_calibration` — a fitted calibration model.

## A 5-minute tour

### Simulate a spectrum

``` r

spec <- ls_simulate_spectrum(line_data = ls_demo_peaks(),
  elements = c(Ca = 5000, Na = 1000, Fe = 200),
  n_channels = 1024,
  seed = 1
)
spec
#> <libs_spectrum>
#> • Range: 200-900 nm (1024 channels)
#> • Shots: 10
#> • Sample: "simulated" (synthetic)
#> • Baseline corrected: FALSE
```

### Plot it

``` r

ls_plot_spectrum(spec)
```

![Fictional teaching spectrum: mean intensity across wavelengths from
200 to 900 nm, including simulated peaks and a continuum
background.](getting-started_files/figure-html/plot-raw-1.png)

### Preprocess: baseline, smooth, normalize

``` r

spec_proc <- spec |>
  ls_baseline(method = "snip", iterations = 40) |>
  ls_smooth(method = "moving_avg", window = 5) |>
  ls_normalize(method = "total")
ls_plot_spectrum(spec_proc)
```

![The same fictional spectrum after SNIP baseline correction,
five-channel moving-average smoothing and total normalization; the
vertical scale is normalized
intensity.](getting-started_files/figure-html/preprocess-1.png)

### Detect peaks without an atomic reference

``` r

peaks <- ls_find_peaks(spec_proc, snr_threshold = 3)
head(peaks)
#> # A tibble: 6 × 6
#>   wavelength_nm intensity   snr prominence fwhm_nm      area
#>           <dbl>     <dbl> <dbl>      <dbl>   <dbl>     <dbl>
#> 1          201.   0.00271  82.6  0.0000910   0.805 0        
#> 2          212.   0.00238  68.0  0.0000943   1.67  0.0000265
#> 3          218.   0.00225  62.0  0.0000563   1.96  0.0000346
#> 4          223.   0.00214  57.3  0.0000348   1.37  0.0000140
#> 5          231.   0.00201  51.1  0.0000384   1.28  0.0000151
#> 6          236.   0.00199  50.3  0.000126    2.62  0.0000874
```

Atomic identification is a separate, optional step. First configure a
reference using the README instructions. These candidates are wavelength
matches, not proof of an element’s presence:

``` r

options(libscanR.element_db = "local-data/atomic-lines.csv")
id <- ls_identify_peaks(peaks, elements = c("Ca", "Na", "Fe"))
ls_plot_spectrum(spec_proc, show_elements = c("Ca", "Na"))
```

### Read from a file

``` r

tmp <- tempfile(fileext = ".csv")
utils::write.csv(
  data.frame(wavelength = spec$wavelength,
             intensity = colMeans(spec$intensity)),
  tmp, row.names = FALSE
)
spec_in <- ls_read_spectrum(tmp, verbose = FALSE)
unlink(tmp)
spec_in
#> <libs_spectrum>
#> • Range: 200-900 nm (1024 channels)
#> • Shots: 1
#> • Sample: "file1db768f14962"
#> • Baseline corrected: FALSE
```

### Use example datasets

``` r

ds <- ls_example_data("tissue")
summary(ds)
#> <libs_dataset> summary
#> • Spectra: 50
#> • Channels: 1024
#> • Range: 200-900 nm
#> ℹ Group counts (column "material"):
#>  material  n
#>      bone 10
#>       fat 10
#>    kidney 10
#>     liver 10
#>    muscle 10
#> ℹ Per-spectrum max intensity: median = 103.79, range =
#> 94.1-319.22
```

## Next steps

- [`vignette("preprocessing-workflow", package = "libscanR")`](https://cttir.github.io/libscanR/dev/articles/preprocessing-workflow.md)
- [`vignette("calibration-quantification", package = "libscanR")`](https://cttir.github.io/libscanR/dev/articles/calibration-quantification.md)
- [`vignette("tissue-classification", package = "libscanR")`](https://cttir.github.io/libscanR/dev/articles/tissue-classification.md)
- [`vignette("spatial-mapping", package = "libscanR")`](https://cttir.github.io/libscanR/dev/articles/spatial-mapping.md)
