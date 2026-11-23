#' libscanR: Analysis and Visualisation of LIBS Spectra
#'
#' A vendor-agnostic pipeline for importing, preprocessing, calibrating, and
#' visualising Laser-Induced Breakdown Spectroscopy (LIBS) spectral data with
#' a focus on biomedical tissue analysis.
#'
#' @section Main functions:
#'
#' * Import: [ls_read_spectrum()], [ls_read_dir()], [ls_read_auto()]
#' * Preprocessing: [ls_baseline()], [ls_normalize()], [ls_smooth()], [ls_crop()]
#' * Peak analysis: [ls_find_peaks()], [ls_identify_peaks()], [ls_element_db()]
#' * Calibration: [ls_calibrate()], [ls_saha_boltzmann()], [ls_quantify()]
#' * Chemometrics: [ls_pca()], [ls_plsda()], [ls_cluster()]
#' * Spatial mapping: [ls_build_map()], [ls_map_elements()]
#' * Tissue analysis: [ls_tissue_classify()], [ls_tissue_discriminate()]
#' * Interactive app: [ls_run_app()]
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom rlang .data
#' @importFrom stats predict
## usethis namespace: end
NULL
