# libscanR: Analysis and Visualization of LIBS Spectra

A vendor-agnostic pipeline for importing, preprocessing, calibrating,
and visualizing Laser-Induced Breakdown Spectroscopy (LIBS) spectral
data with a focus on biomedical tissue analysis.

## Main functions

- Import:
  [`ls_read_spectrum()`](https://cttir.github.io/libscanR/reference/ls_read_spectrum.md),
  [`ls_read_dir()`](https://cttir.github.io/libscanR/reference/ls_read_dir.md),
  [`ls_read_auto()`](https://cttir.github.io/libscanR/reference/ls_read_auto.md)

- Preprocessing:
  [`ls_baseline()`](https://cttir.github.io/libscanR/reference/ls_baseline.md),
  [`ls_normalize()`](https://cttir.github.io/libscanR/reference/ls_normalize.md),
  [`ls_smooth()`](https://cttir.github.io/libscanR/reference/ls_smooth.md),
  [`ls_crop()`](https://cttir.github.io/libscanR/reference/ls_crop.md)

- Peak analysis:
  [`ls_find_peaks()`](https://cttir.github.io/libscanR/reference/ls_find_peaks.md),
  [`ls_identify_peaks()`](https://cttir.github.io/libscanR/reference/ls_identify_peaks.md),
  [`ls_element_db()`](https://cttir.github.io/libscanR/reference/ls_element_db.md)

- Calibration:
  [`ls_calibrate()`](https://cttir.github.io/libscanR/reference/ls_calibrate.md),
  [`ls_saha_boltzmann()`](https://cttir.github.io/libscanR/reference/ls_saha_boltzmann.md),
  [`ls_quantify()`](https://cttir.github.io/libscanR/reference/ls_quantify.md)

- Chemometrics:
  [`ls_pca()`](https://cttir.github.io/libscanR/reference/ls_pca.md),
  [`ls_plsda()`](https://cttir.github.io/libscanR/reference/ls_plsda.md),
  [`ls_cluster()`](https://cttir.github.io/libscanR/reference/ls_cluster.md)

- Spatial mapping:
  [`ls_build_map()`](https://cttir.github.io/libscanR/reference/ls_build_map.md),
  [`ls_map_elements()`](https://cttir.github.io/libscanR/reference/ls_map_elements.md)

- Tissue analysis:
  [`ls_tissue_classify()`](https://cttir.github.io/libscanR/reference/ls_tissue_classify.md),
  [`ls_tissue_discriminate()`](https://cttir.github.io/libscanR/reference/ls_tissue_discriminate.md)

- Interactive app:
  [`ls_run_app()`](https://cttir.github.io/libscanR/reference/ls_run_app.md)

## See also

Useful links:

- <https://github.com/r-heller/libscanR>

- <https://r-heller.github.io/libscanR/>

- Report bugs at <https://github.com/r-heller/libscanR/issues>

## Author

**Maintainer**: Raban Heller <raban.heller@charite.de>
([ORCID](https://orcid.org/0000-0001-8006-9742))
