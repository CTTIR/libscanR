# libscanR

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.21889942.svg)](https://doi.org/10.5281/zenodo.21889942)

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

## License

MIT © Raban Heller

## Use of LLM tools

Where applicable, LLM tools were used for narrowly defined,
non-authorial tasks: copyediting, prose refinement, Markdown/LaTeX
formatting, boilerplate scaffolding (such as CI configurations and build
scripts), and code refactoring. Tools included [Chat
AI](https://kisski.gwdg.de/leistungen/2-02-llm-service/), the KISSKI
(GWDG) service, and self-hosted **Mistral Small (24B, Apache-2.0)**
served through a local **vLLM architecture** on an Ubuntu Linux
workstation with Intel processors and NVIDIA GPUs. The self-hosted model
ran locally, with no data sent to third parties.

All scientific claims, methodological choices, analyses, interpretations
and conclusions remain the authors’ own. Where applicable, LLM-generated
material must be reviewed and revised before inclusion, and references
must be verified against their DOI, arXiv ID or ISBN.

Workstation software snapshot (14 October 2026): local,
OpenAI-compatible vLLM serving with **vLLM
0.28.1rc1.dev534+g613ab20f7**, **Python 3.12.13** and **PyTorch
2.13.0**; **R 4.6.1** and **RStudio 2026.06.0+242**. These are
workstation versions, not per-project dependency or validation
requirements.
