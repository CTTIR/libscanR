# libscanR

Vendor-agnostic analysis and visualization of **Laser-Induced Breakdown
Spectroscopy (LIBS)** data in R, with a focus on biomedical tissue
applications.

## Features

- **Import**: Generic CSV/TSV/TXT, SciAps Z-series, Applied Spectra
  J200/Aurora, auto-detection.
- **Preprocessing**: SNIP/ALS baseline correction, five normalization
  modes, Savitzky-Golay / Gaussian / moving-average / median smoothing,
  shot averaging with outlier removal, wavelength cropping, gate delay
  optimization.
- **Peak analysis**: SNR+prominence peak detection; identification
  against a curated NIST emission-line database (23 biomedically
  relevant elements).
- **Calibration**: Univariate, internal-standard, PLS, and
  calibration-free LIBS (Saha-Boltzmann). LOD / LOQ with 3σ / 10σ
  criteria.
- **Chemometrics**: PCA, PLS-DA, k-means / hierarchical clustering, SVM
  / Random-Forest classifiers.
- **Tissue analysis**: Rule-based tissue classification using elemental
  ratios; discriminating-line analysis with FDR correction.
- **Spatial mapping**: Single-element and multi-element 2-D maps from
  raster-scan datasets.
- **Visualization**: Publication-ready ggplot2 plots; custom
  [`theme_libs()`](https://cttir.github.io/libscanR/reference/theme_libs.md)
  and wavelength color scale.
- **Shiny app**: Six-tab interactive explorer
  ([`ls_run_app()`](https://cttir.github.io/libscanR/reference/ls_run_app.md)).
- **Reproducible examples**:
  [`ls_example_data()`](https://cttir.github.io/libscanR/reference/ls_example_data.md)
  provides synthetic tissue, calibration, and spatial datasets — no
  instrument data required.

## Installation

``` r

# install.packages("remotes")
remotes::install_github("cttir/libscanR")
```

## Quick start

``` r

library(libscanR)

# Generate a synthetic spectrum
spec <- ls_simulate_spectrum(
  elements = c(Ca = 5000, Na = 1000, Fe = 200),
  seed = 1
)

# Preprocess: baseline, smooth, normalize
spec_proc <- spec |>
  ls_baseline(method = "snip") |>
  ls_smooth(method = "moving_avg", window = 5) |>
  ls_normalize(method = "total")

# Detect and identify peaks
peaks <- ls_find_peaks(spec_proc)
id <- ls_identify_peaks(peaks, elements = c("Ca", "Na", "Fe"))

# Plot with element annotation
ls_plot_spectrum(spec_proc, show_elements = c("Ca", "Na"))

# Launch the interactive app
ls_run_app(data = ls_example_data("tissue"))
```

## Workflow vignettes

- [`vignette("getting-started", package = "libscanR")`](https://cttir.github.io/libscanR/articles/getting-started.md)
- [`vignette("preprocessing-workflow", package = "libscanR")`](https://cttir.github.io/libscanR/articles/preprocessing-workflow.md)
- [`vignette("calibration-quantification", package = "libscanR")`](https://cttir.github.io/libscanR/articles/calibration-quantification.md)
- [`vignette("tissue-classification", package = "libscanR")`](https://cttir.github.io/libscanR/articles/tissue-classification.md)
- [`vignette("spatial-mapping", package = "libscanR")`](https://cttir.github.io/libscanR/articles/spatial-mapping.md)

## Citation

``` r

citation("libscanR")
```

## Use of LLM tools

Portions of this package were prepared with assistance from large
language model tooling for narrowly defined, non-authorial tasks:
copyediting, prose smoothing, Markdown/LaTeX formatting, scaffolding of
boilerplate files (CI configs, build scripts), code refactoring. The
tools used were [Chat
AI](https://kisski.gwdg.de/leistungen/2-02-llm-service/), the LLM
service of KISSKI (GWDG), and a self-hosted **Mistral Small (24B,
Apache-2.0)** run locally via [Ollama](https://ollama.com/) and the
`ollamar` R package — local inference only, with no data sent to third
parties for the self-hosted model.

All scientific claims, methodological choices, analyses,
interpretations, and conclusions are the author’s own. No LLM-generated
text was incorporated without review and revision, and every reference
was verified against its DOI, arXiv ID, or ISBN.

## License

MIT © Raban Heller
