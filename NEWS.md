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
