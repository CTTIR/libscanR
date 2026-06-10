# Package index

## Package

- [`libscanR`](https://cttir.github.io/libscanR/reference/libscanR-package.md)
  [`libscanR-package`](https://cttir.github.io/libscanR/reference/libscanR-package.md)
  : libscanR: Analysis and Visualization of LIBS Spectra

## Import & Export

- [`ls_read_spectrum()`](https://cttir.github.io/libscanR/reference/ls_read_spectrum.md)
  : Read a LIBS Spectrum from File
- [`ls_read_dir()`](https://cttir.github.io/libscanR/reference/ls_read_dir.md)
  : Read All Spectra from a Directory
- [`ls_read_csv()`](https://cttir.github.io/libscanR/reference/ls_read_csv.md)
  : Read a LIBS Spectrum from CSV (Convenience Wrapper)
- [`ls_read_sciaps()`](https://cttir.github.io/libscanR/reference/ls_read_sciaps.md)
  : Read SciAps LIBS Data
- [`ls_read_aurora()`](https://cttir.github.io/libscanR/reference/ls_read_aurora.md)
  : Read Applied Spectra / Aurora Data
- [`ls_read_auto()`](https://cttir.github.io/libscanR/reference/ls_read_auto.md)
  : Auto-Detect and Read LIBS Data
- [`ls_write_csv()`](https://cttir.github.io/libscanR/reference/ls_write_csv.md)
  : Write a LIBS Spectrum to CSV
- [`ls_export_spectra()`](https://cttir.github.io/libscanR/reference/ls_export_spectra.md)
  : Export a LIBS Dataset to a Directory

## Data Structures

- [`ls_spectrum()`](https://cttir.github.io/libscanR/reference/ls_spectrum.md)
  : Create a LIBS Spectrum Object
- [`ls_dataset()`](https://cttir.github.io/libscanR/reference/ls_dataset.md)
  : Create a LIBS Dataset
- [`ls_calibration()`](https://cttir.github.io/libscanR/reference/ls_calibration.md)
  : Create a LIBS Calibration Model
- [`is_libs_spectrum()`](https://cttir.github.io/libscanR/reference/is_libs_spectrum.md)
  : Test whether an object is a libs_spectrum
- [`is_libs_dataset()`](https://cttir.github.io/libscanR/reference/is_libs_dataset.md)
  : Test whether an object is a libs_dataset
- [`is_libs_calibration()`](https://cttir.github.io/libscanR/reference/is_libs_calibration.md)
  : Test whether an object is a libs_calibration

## Preprocessing

- [`ls_baseline()`](https://cttir.github.io/libscanR/reference/ls_baseline.md)
  : Baseline Correction
- [`ls_normalize()`](https://cttir.github.io/libscanR/reference/ls_normalize.md)
  : Normalize Spectra
- [`ls_smooth()`](https://cttir.github.io/libscanR/reference/ls_smooth.md)
  : Smooth Spectra
- [`ls_crop()`](https://cttir.github.io/libscanR/reference/ls_crop.md) :
  Crop Spectral Range
- [`ls_average_shots()`](https://cttir.github.io/libscanR/reference/ls_average_shots.md)
  : Average Replicate Shots
- [`ls_gate_optimize()`](https://cttir.github.io/libscanR/reference/ls_gate_optimize.md)
  : Gate Delay Optimization

## Peak Analysis

- [`ls_find_peaks()`](https://cttir.github.io/libscanR/reference/ls_find_peaks.md)
  : Find Emission Peaks
- [`ls_identify_peaks()`](https://cttir.github.io/libscanR/reference/ls_identify_peaks.md)
  : Identify Peaks Against the NIST Line Database
- [`ls_peak_area()`](https://cttir.github.io/libscanR/reference/ls_peak_area.md)
  : Calculate Peak Area
- [`ls_element_db()`](https://cttir.github.io/libscanR/reference/ls_element_db.md)
  : NIST Emission Line Database

## Calibration & Quantification

- [`ls_calibrate()`](https://cttir.github.io/libscanR/reference/ls_calibrate.md)
  : Build Calibration Curve
- [`ls_saha_boltzmann()`](https://cttir.github.io/libscanR/reference/ls_saha_boltzmann.md)
  : Calibration-Free LIBS via Saha-Boltzmann
- [`ls_quantify()`](https://cttir.github.io/libscanR/reference/ls_quantify.md)
  : Quantify Element Concentration
- [`ls_lod()`](https://cttir.github.io/libscanR/reference/ls_lod.md) :
  Limit of Detection (3-sigma)
- [`ls_loq()`](https://cttir.github.io/libscanR/reference/ls_loq.md) :
  Limit of Quantification (10-sigma)

## Chemometrics

- [`ls_pca()`](https://cttir.github.io/libscanR/reference/ls_pca.md) :
  Principal Component Analysis of LIBS Spectra
- [`ls_plsda()`](https://cttir.github.io/libscanR/reference/ls_plsda.md)
  : PLS-DA Classification
- [`ls_cluster()`](https://cttir.github.io/libscanR/reference/ls_cluster.md)
  : Cluster LIBS Spectra
- [`ls_classify()`](https://cttir.github.io/libscanR/reference/ls_classify.md)
  : Classify Unknown Spectra
- [`ls_train_classifier()`](https://cttir.github.io/libscanR/reference/ls_train_classifier.md)
  : Train a Classifier

## Spatial Mapping

- [`ls_build_map()`](https://cttir.github.io/libscanR/reference/ls_build_map.md)
  : Build a Spatial Elemental Map
- [`ls_map_elements()`](https://cttir.github.io/libscanR/reference/ls_map_elements.md)
  : Build Maps for Multiple Elements

## Tissue Analysis

- [`ls_tissue_classify()`](https://cttir.github.io/libscanR/reference/ls_tissue_classify.md)
  : Tissue Classification via LIBS
- [`ls_tissue_discriminate()`](https://cttir.github.io/libscanR/reference/ls_tissue_discriminate.md)
  : Tissue Discrimination Analysis

## Visualization

- [`ls_plot_spectrum()`](https://cttir.github.io/libscanR/reference/ls_plot_spectrum.md)
  : Plot a LIBS Spectrum
- [`ls_plot_overlay()`](https://cttir.github.io/libscanR/reference/ls_plot_overlay.md)
  : Overlay Multiple Spectra
- [`ls_plot_region()`](https://cttir.github.io/libscanR/reference/ls_plot_region.md)
  : Plot a Spectral Region in Detail
- [`ls_plot_calibration()`](https://cttir.github.io/libscanR/reference/ls_plot_calibration.md)
  : Plot a Calibration Curve
- [`ls_plot_residuals()`](https://cttir.github.io/libscanR/reference/ls_plot_residuals.md)
  : Plot Calibration Residuals
- [`ls_plot_map()`](https://cttir.github.io/libscanR/reference/ls_plot_map.md)
  : Plot an Elemental Map
- [`ls_plot_map_panel()`](https://cttir.github.io/libscanR/reference/ls_plot_map_panel.md)
  : Plot Multi-Element Map Panel
- [`ls_plot_element_map()`](https://cttir.github.io/libscanR/reference/ls_plot_element_map.md)
  : Plot an Element Map (alias)
- [`ls_plot_pca()`](https://cttir.github.io/libscanR/reference/ls_plot_pca.md)
  : Plot PCA Scores
- [`ls_plot_loadings()`](https://cttir.github.io/libscanR/reference/ls_plot_loadings.md)
  : Plot PCA Loadings
- [`ls_plot_scree()`](https://cttir.github.io/libscanR/reference/ls_plot_scree.md)
  : Plot PCA Variance (Scree Plot)
- [`ls_plot_plsda()`](https://cttir.github.io/libscanR/reference/ls_plot_plsda.md)
  : Plot PLS-DA Results
- [`theme_libs()`](https://cttir.github.io/libscanR/reference/theme_libs.md)
  : LIBS Theme for ggplot2
- [`scale_color_wavelength()`](https://cttir.github.io/libscanR/reference/scale_color_wavelength.md)
  : Wavelength-Based Color Scale

## Shiny Application

- [`ls_run_app()`](https://cttir.github.io/libscanR/reference/ls_run_app.md)
  : Launch the libscanR Shiny Application

## Example Data

- [`ls_simulate_spectrum()`](https://cttir.github.io/libscanR/reference/ls_simulate_spectrum.md)
  : Simulate a LIBS Spectrum
- [`ls_example_data()`](https://cttir.github.io/libscanR/reference/ls_example_data.md)
  : Generate Example LIBS Dataset

## S3 Methods

- [`c(`*`<libs_spectrum>`*`)`](https://cttir.github.io/libscanR/reference/c.libs_spectrum.md)
  : Combine Multiple LIBS Spectra by Stacking Shots
- [`dim(`*`<libs_dataset>`*`)`](https://cttir.github.io/libscanR/reference/dim.libs_dataset.md)
  : Dimensions of a Dataset (spectra x channels)
- [`dim(`*`<libs_spectrum>`*`)`](https://cttir.github.io/libscanR/reference/dim.libs_spectrum.md)
  : Dimensions of a LIBS Spectrum (shots x channels)
- [`length(`*`<libs_dataset>`*`)`](https://cttir.github.io/libscanR/reference/length.libs_dataset.md)
  : Number of Spectra in a Dataset
- [`length(`*`<libs_spectrum>`*`)`](https://cttir.github.io/libscanR/reference/length.libs_spectrum.md)
  : Number of Channels in a LIBS Spectrum
- [`plot(`*`<libs_dataset>`*`)`](https://cttir.github.io/libscanR/reference/plot.libs_dataset.md)
  : Plot a LIBS Dataset
- [`plot(`*`<libs_spectrum>`*`)`](https://cttir.github.io/libscanR/reference/plot.libs_spectrum.md)
  : Plot a LIBS Spectrum
- [`predict(`*`<libs_calibration>`*`)`](https://cttir.github.io/libscanR/reference/predict.libs_calibration.md)
  : Predict Concentrations from a Calibration Model
- [`print(`*`<libs_calibration>`*`)`](https://cttir.github.io/libscanR/reference/print.libs_calibration.md)
  : Print a LIBS Calibration
- [`print(`*`<libs_dataset>`*`)`](https://cttir.github.io/libscanR/reference/print.libs_dataset.md)
  : Print a LIBS Dataset
- [`print(`*`<libs_spectrum>`*`)`](https://cttir.github.io/libscanR/reference/print.libs_spectrum.md)
  : Print a LIBS Spectrum
- [`` `[`( ``*`<libs_dataset>`*`)`](https://cttir.github.io/libscanR/reference/sub-.libs_dataset.md)
  : Subset a LIBS Dataset
- [`` `[`( ``*`<libs_spectrum>`*`)`](https://cttir.github.io/libscanR/reference/sub-.libs_spectrum.md)
  : Subset a LIBS Spectrum by Wavelength
- [`summary(`*`<libs_calibration>`*`)`](https://cttir.github.io/libscanR/reference/summary.libs_calibration.md)
  : Summary of a LIBS Calibration
- [`summary(`*`<libs_dataset>`*`)`](https://cttir.github.io/libscanR/reference/summary.libs_dataset.md)
  : Summary of a LIBS Dataset
- [`summary(`*`<libs_spectrum>`*`)`](https://cttir.github.io/libscanR/reference/summary.libs_spectrum.md)
  : Summary of a LIBS Spectrum
