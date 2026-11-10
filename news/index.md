# Changelog

## libscanR 0.2.0

- Prepare the first CRAN submission: every exported function and S3
  method now has a runnable example, the title fits CRAN’s 65-character
  limit, the maintainer address is updated and `Language: en-US` is
  declared.

- Keep channel baselines, sample IDs, sample tables and cached
  intensities aligned; reject malformed spectra, duplicate IDs and
  different wavelength axes.

- Round-trip default CSV exports and preserve the first
  vendor/headerless data row. Validate all output filenames, stage
  exports, preserve existing bundles when overwrite is false, and
  restore previous files on ordinary write failures.

- Correct integer spectrum subsetting, combined baseline summaries,
  normalized peak markers, constant-shot averaging and seeded example
  reproducibility.

- Correct SNIP traversal dependence and the local Savitzky-Golay
  intercept; use sparse ALS equations and retain preprocessing/baseline
  provenance.

- Reject out-of-range peak centers and duplicate map coordinates.
  Calibrated maps use the spectrum prediction path. Document
  coarse-channel integration expansion and the Gaussian demonstration
  model’s limits.

- Remove bundled atomic-reference tables. Load a user-supplied CSV/RDS
  through an explicit path, option or environment variable; provide a
  local NIST CSV converter with provenance hashes and no network
  requests. Keep missing values explicit. Peak-match confidence remains
  a wavelength-distance score, not a probability; report the number of
  candidate transitions.

- Separate fictional teaching peaks from configured atomic simulation.
  Examples and tests run without downloads; spectra record the selected
  source type. Statistical discrimination and ordinary plots remain
  usable without optional atomic annotations, which are explicitly
  marked unavailable.

- Replace the incomplete Saha-Boltzmann calculation with an explicit
  two-stage LTE model using density, statistical weights, partition
  functions and instrument response. Require complete physical inputs
  and resolved measured lines; report relative number fractions and
  assumptions. Previous results must be recalculated. Independent
  high-precision synthetic forward models verify the implemented
  equations without claiming experimental validation.

- Require exact structural and metadata field names so similarly named
  fields cannot silently supply sample identities, processing history or
  wavelength medium.

- Reject non-converged Gaussian peak fits; report a named warning and
  use the trapezoidal area rather than returning an unconverged fitted
  value.

- Mark citation and archival metadata as a development draft; remove
  badges for an unconfirmed CRAN release and unresolved archival
  identifier.

- Preserve fitted calibration windows, internal-standard ratios and PLS
  features when predicting. Require the fitted wavelength axis and
  ordered preprocessing; incompatible legacy spectral models need
  refitting. Correct estimated LOD/LOQ units and use replicated blank
  responses; report PLS limits as unavailable.

- Use actual held-out predictions for PLS-DA CV and LOO, bound
  components by each training fold, and label training, out-of-bag and
  held-out evaluation explicitly. Align SVM training summaries with the
  public probability-based prediction rule. Correct singleton/noise
  silhouette handling and reject invalid clustering inputs.

- Make tissue heuristics invariant to detector gain and leave missing
  signal or local spectral coverage unclassified. Replace ambiguous
  confidence values with labelled scores; remove the unit-dependent
  fold-change pseudocount.

- Show actual linear prediction intervals and full-model PLS training
  predictions; keep numeric PCA colors continuous and distinguish
  dispersion from uncertainty.

- Preserve uploads and processing state on failures; invalidate stale
  analyses and exports after data or setting changes. Export every shot
  with metadata in ZIP bundles and label mean-spectrum and
  calibration-summary CSV files clearly. Require Shiny 1.6.0 and bslib
  0.5.0 for the explorer and a working ZIP utility for bundle downloads.
  Restore temporary data-directory options on exit.

## libscanR 0.1.0

- Standardize the named v5 package logo across README, documentation
  pages and available application headers, with matching light and dark
  artwork.

### Initial release

#### Import & Export

- [`ls_read_spectrum()`](https://cttir.github.io/libscanR/reference/ls_read_spectrum.md):
  Read individual LIBS spectra from CSV/TSV/TXT.
- [`ls_read_dir()`](https://cttir.github.io/libscanR/reference/ls_read_dir.md):
  Batch-import spectra from a directory.
- [`ls_read_csv()`](https://cttir.github.io/libscanR/reference/ls_read_csv.md):
  Convenience wrapper for CSV files.
- [`ls_read_sciaps()`](https://cttir.github.io/libscanR/reference/ls_read_sciaps.md),
  [`ls_read_aurora()`](https://cttir.github.io/libscanR/reference/ls_read_aurora.md):
  Vendor-specific parsers.
- [`ls_read_auto()`](https://cttir.github.io/libscanR/reference/ls_read_auto.md):
  Auto-detect format and dispatch to correct reader.
- [`ls_write_csv()`](https://cttir.github.io/libscanR/reference/ls_write_csv.md),
  [`ls_export_spectra()`](https://cttir.github.io/libscanR/reference/ls_export_spectra.md):
  Export processed data.

#### Data Structures

- S3 classes: `libs_spectrum`, `libs_dataset`, `libs_calibration`.
- Print, summary, subset, plot, length, dim, and combine methods.
- Helper predicates:
  [`is_libs_spectrum()`](https://cttir.github.io/libscanR/reference/is_libs_spectrum.md),
  [`is_libs_dataset()`](https://cttir.github.io/libscanR/reference/is_libs_dataset.md),
  [`is_libs_calibration()`](https://cttir.github.io/libscanR/reference/is_libs_calibration.md).

#### Preprocessing

- [`ls_baseline()`](https://cttir.github.io/libscanR/reference/ls_baseline.md):
  SNIP, ALS, rolling ball, linear, polynomial.
- [`ls_normalize()`](https://cttir.github.io/libscanR/reference/ls_normalize.md):
  Total, max, SNV, internal standard, area.
- [`ls_smooth()`](https://cttir.github.io/libscanR/reference/ls_smooth.md):
  Savitzky-Golay, moving average, Gaussian, median.
- [`ls_average_shots()`](https://cttir.github.io/libscanR/reference/ls_average_shots.md):
  Shot averaging with outlier removal.
- [`ls_crop()`](https://cttir.github.io/libscanR/reference/ls_crop.md):
  Spectral range subsetting.
- [`ls_gate_optimize()`](https://cttir.github.io/libscanR/reference/ls_gate_optimize.md):
  Optimize acquisition gate delay.

#### Peak Analysis

- [`ls_find_peaks()`](https://cttir.github.io/libscanR/reference/ls_find_peaks.md):
  Peak detection with SNR, prominence, distance filters.
- [`ls_identify_peaks()`](https://cttir.github.io/libscanR/reference/ls_identify_peaks.md):
  Match detected peaks against the NIST database.
- [`ls_peak_area()`](https://cttir.github.io/libscanR/reference/ls_peak_area.md):
  Integrate peak area with baseline subtraction.
- [`ls_element_db()`](https://cttir.github.io/libscanR/reference/ls_element_db.md):
  Curated NIST emission lines for 23 elements.

#### Calibration & Quantification

- [`ls_calibrate()`](https://cttir.github.io/libscanR/reference/ls_calibrate.md):
  Univariate, internal standard, and PLS calibration.
- [`ls_saha_boltzmann()`](https://cttir.github.io/libscanR/reference/ls_saha_boltzmann.md):
  Calibration-free LIBS (Boltzmann plot).
- [`ls_quantify()`](https://cttir.github.io/libscanR/reference/ls_quantify.md):
  Apply calibration to unknowns with LOD/LOQ flags.
- [`ls_lod()`](https://cttir.github.io/libscanR/reference/ls_lod.md),
  [`ls_loq()`](https://cttir.github.io/libscanR/reference/ls_loq.md):
  Figures of merit.

#### Chemometrics

- [`ls_pca()`](https://cttir.github.io/libscanR/reference/ls_pca.md):
  Principal component analysis.
- [`ls_plsda()`](https://cttir.github.io/libscanR/reference/ls_plsda.md):
  PLS-DA classification with cross-validation.
- [`ls_cluster()`](https://cttir.github.io/libscanR/reference/ls_cluster.md):
  K-means and hierarchical clustering.
- [`ls_train_classifier()`](https://cttir.github.io/libscanR/reference/ls_train_classifier.md):
  SVM and Random Forest training.
- [`ls_classify()`](https://cttir.github.io/libscanR/reference/ls_classify.md):
  Predict class for unknown spectra.

#### Spatial Mapping

- [`ls_build_map()`](https://cttir.github.io/libscanR/reference/ls_build_map.md):
  Build elemental distribution maps.
- [`ls_map_elements()`](https://cttir.github.io/libscanR/reference/ls_map_elements.md):
  Multi-element map construction.

#### Tissue Analysis

- [`ls_tissue_classify()`](https://cttir.github.io/libscanR/reference/ls_tissue_classify.md):
  Ratio-based and model-based tissue classification.
- [`ls_tissue_discriminate()`](https://cttir.github.io/libscanR/reference/ls_tissue_discriminate.md):
  Identify discriminating emission lines.

#### Visualization

- [`ls_plot_spectrum()`](https://cttir.github.io/libscanR/reference/ls_plot_spectrum.md),
  [`ls_plot_overlay()`](https://cttir.github.io/libscanR/reference/ls_plot_overlay.md),
  [`ls_plot_region()`](https://cttir.github.io/libscanR/reference/ls_plot_region.md):
  Spectrum plots.
- [`ls_plot_calibration()`](https://cttir.github.io/libscanR/reference/ls_plot_calibration.md),
  [`ls_plot_residuals()`](https://cttir.github.io/libscanR/reference/ls_plot_residuals.md):
  Calibration diagnostics.
- [`ls_plot_map()`](https://cttir.github.io/libscanR/reference/ls_plot_map.md),
  [`ls_plot_map_panel()`](https://cttir.github.io/libscanR/reference/ls_plot_map_panel.md),
  [`ls_plot_element_map()`](https://cttir.github.io/libscanR/reference/ls_plot_element_map.md):
  Elemental maps.
- [`ls_plot_pca()`](https://cttir.github.io/libscanR/reference/ls_plot_pca.md),
  [`ls_plot_loadings()`](https://cttir.github.io/libscanR/reference/ls_plot_loadings.md),
  [`ls_plot_scree()`](https://cttir.github.io/libscanR/reference/ls_plot_scree.md):
  PCA plots.
- [`ls_plot_plsda()`](https://cttir.github.io/libscanR/reference/ls_plot_plsda.md):
  PLS-DA diagnostic plots.
- [`theme_libs()`](https://cttir.github.io/libscanR/reference/theme_libs.md),
  [`scale_color_wavelength()`](https://cttir.github.io/libscanR/reference/scale_color_wavelength.md):
  ggplot2 helpers.

#### Shiny Application

- [`ls_run_app()`](https://cttir.github.io/libscanR/reference/ls_run_app.md):
  Interactive spectral explorer with six tabs (Import, Preprocess,
  Peaks, Calibration, Chemometrics, Export).

#### Example Data

- [`ls_simulate_spectrum()`](https://cttir.github.io/libscanR/reference/ls_simulate_spectrum.md):
  Realistic synthetic LIBS spectra.
- [`ls_example_data()`](https://cttir.github.io/libscanR/reference/ls_example_data.md):
  Tissue, calibration, and spatial scenarios.
