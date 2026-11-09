# libscanR 0.2.0

* Prepare the first CRAN submission: every exported function and S3 method now
  has a runnable example, the title fits CRAN's 65-character limit, the
  maintainer address is updated and `Language: en-US` is declared.

* Keep channel baselines, sample IDs, sample tables and cached intensities aligned;
  reject malformed spectra, duplicate IDs and different wavelength axes.
* Round-trip default CSV exports and preserve the first vendor/headerless data row.
  Validate all output filenames, stage exports, preserve existing bundles when
  overwrite is false, and restore previous files on ordinary write failures.
* Correct integer spectrum subsetting, combined baseline summaries, normalized
  peak markers, constant-shot averaging and seeded example reproducibility.
* Correct SNIP traversal dependence and the local Savitzky-Golay intercept;
  use sparse ALS equations and retain preprocessing/baseline provenance.
* Reject out-of-range peak centers and duplicate map coordinates. Calibrated maps
  use the spectrum prediction path. Document coarse-channel integration expansion
  and the Gaussian demonstration model's limits.
* Remove bundled atomic-reference tables. Load a user-supplied CSV/RDS through
  an explicit path, option or environment variable; provide a local NIST CSV
  converter with provenance hashes and no network requests. Keep missing values
  explicit. Peak-match confidence remains a wavelength-distance score, not a
  probability; report the number of candidate transitions.
* Separate fictional teaching peaks from configured atomic simulation. Examples
  and tests run without downloads; spectra record the selected source type.
  Statistical discrimination and ordinary plots remain usable without optional
  atomic annotations, which are explicitly marked unavailable.
* Replace the incomplete Saha-Boltzmann calculation with an explicit two-stage
  LTE model using density, statistical weights, partition functions and
  instrument response. Require complete physical inputs and resolved measured
  lines; report relative number fractions and assumptions. Previous results
  must be recalculated. Independent high-precision synthetic forward models
  verify the implemented equations without claiming experimental validation.
* Require exact structural and metadata field names so similarly named fields
  cannot silently supply sample identities, processing history or wavelength medium.
* Reject non-converged Gaussian peak fits; report a named warning and use the
  trapezoidal area rather than returning an unconverged fitted value.
* Mark citation and archival metadata as a development draft; remove badges for
  an unconfirmed CRAN release and unresolved archival identifier.
* Preserve fitted calibration windows, internal-standard ratios and PLS features
  when predicting. Require the fitted wavelength axis and ordered preprocessing;
  incompatible legacy spectral models need refitting. Correct estimated LOD/LOQ
  units and use replicated blank responses; report PLS limits as unavailable.
* Use actual held-out predictions for PLS-DA CV and LOO, bound components by each
  training fold, and label training, out-of-bag and held-out evaluation explicitly.
  Align SVM training summaries with the public probability-based prediction rule.
  Correct singleton/noise silhouette handling and reject invalid clustering inputs.
* Make tissue heuristics invariant to detector gain and leave missing signal or
  local spectral coverage unclassified. Replace ambiguous confidence values with
  labelled scores; remove the unit-dependent fold-change pseudocount.
* Show actual linear prediction intervals and full-model PLS training predictions;
  keep numeric PCA colors continuous and distinguish dispersion from uncertainty.
* Preserve uploads and processing state on failures; invalidate stale analyses
  and exports after data or setting changes. Export every shot with metadata in
  ZIP bundles and label mean-spectrum and calibration-summary CSV files clearly.
  Require Shiny 1.6.0 and bslib 0.5.0 for the explorer and a working ZIP utility
  for bundle downloads. Restore temporary data-directory options on exit.

# libscanR 0.1.0

* Standardize the named v5 package logo across README, documentation pages
  and available application headers, with matching light and dark artwork.


## Initial release

### Import & Export
* `ls_read_spectrum()`: Read individual LIBS spectra from CSV/TSV/TXT.
* `ls_read_dir()`: Batch-import spectra from a directory.
* `ls_read_csv()`: Convenience wrapper for CSV files.
* `ls_read_sciaps()`, `ls_read_aurora()`: Vendor-specific parsers.
* `ls_read_auto()`: Auto-detect format and dispatch to correct reader.
* `ls_write_csv()`, `ls_export_spectra()`: Export processed data.

### Data Structures
* S3 classes: `libs_spectrum`, `libs_dataset`, `libs_calibration`.
* Print, summary, subset, plot, length, dim, and combine methods.
* Helper predicates: `is_libs_spectrum()`, `is_libs_dataset()`,
  `is_libs_calibration()`.

### Preprocessing
* `ls_baseline()`: SNIP, ALS, rolling ball, linear, polynomial.
* `ls_normalize()`: Total, max, SNV, internal standard, area.
* `ls_smooth()`: Savitzky-Golay, moving average, Gaussian, median.
* `ls_average_shots()`: Shot averaging with outlier removal.
* `ls_crop()`: Spectral range subsetting.
* `ls_gate_optimize()`: Optimize acquisition gate delay.

### Peak Analysis
* `ls_find_peaks()`: Peak detection with SNR, prominence, distance filters.
* `ls_identify_peaks()`: Match detected peaks against the NIST database.
* `ls_peak_area()`: Integrate peak area with baseline subtraction.
* `ls_element_db()`: Curated NIST emission lines for 23 elements.

### Calibration & Quantification
* `ls_calibrate()`: Univariate, internal standard, and PLS calibration.
* `ls_saha_boltzmann()`: Calibration-free LIBS (Boltzmann plot).
* `ls_quantify()`: Apply calibration to unknowns with LOD/LOQ flags.
* `ls_lod()`, `ls_loq()`: Figures of merit.

### Chemometrics
* `ls_pca()`: Principal component analysis.
* `ls_plsda()`: PLS-DA classification with cross-validation.
* `ls_cluster()`: K-means and hierarchical clustering.
* `ls_train_classifier()`: SVM and Random Forest training.
* `ls_classify()`: Predict class for unknown spectra.

### Spatial Mapping
* `ls_build_map()`: Build elemental distribution maps.
* `ls_map_elements()`: Multi-element map construction.

### Tissue Analysis
* `ls_tissue_classify()`: Ratio-based and model-based tissue classification.
* `ls_tissue_discriminate()`: Identify discriminating emission lines.

### Visualization
* `ls_plot_spectrum()`, `ls_plot_overlay()`, `ls_plot_region()`: Spectrum plots.
* `ls_plot_calibration()`, `ls_plot_residuals()`: Calibration diagnostics.
* `ls_plot_map()`, `ls_plot_map_panel()`, `ls_plot_element_map()`: Elemental maps.
* `ls_plot_pca()`, `ls_plot_loadings()`, `ls_plot_scree()`: PCA plots.
* `ls_plot_plsda()`: PLS-DA diagnostic plots.
* `theme_libs()`, `scale_color_wavelength()`: ggplot2 helpers.

### Shiny Application
* `ls_run_app()`: Interactive spectral explorer with six tabs
  (Import, Preprocess, Peaks, Calibration, Chemometrics, Export).

### Example Data
* `ls_simulate_spectrum()`: Realistic synthetic LIBS spectra.
* `ls_example_data()`: Tissue, calibration, and spatial scenarios.
