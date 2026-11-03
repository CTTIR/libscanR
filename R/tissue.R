# Tissue-specific classification and discrimination
# -----------------------------------------------------------------------------

# Canonical lines for tissue analysis
.tissue_lines <- c(
  Ca = 393.37, Na = 589.00, K = 766.49, Mg = 279.55,
  Fe = 371.99, Zn = 213.86, Cu = 324.75, P = 213.62,
  C = 247.86, H = 656.28
)

# Rule-based tissue discrimination using elemental ratios.
# Returns a relative heuristic score, or an explicit unclassified result.
#' @keywords internal
#' @noRd
.classify_by_ratio <- function(s) {
  .validate_spectrum(s)
  lines <- .tissue_lines[c("Ca", "Na", "K", "Fe", "C")]
  unavailable <- function(status, areas = rep(NA_real_, length(lines))) {
    list(tissue = NA_character_, score = NA_real_, scores = NULL,
         areas = areas, status = status)
  }
  effective_window <- max(1, 5 * stats::median(diff(s$wavelength)))
  covered <- vapply(lines, function(wl) {
    sum(s$wavelength >= wl - effective_window / 2 &
          s$wavelength <= wl + effective_window / 2) >= 3L
  }, logical(1))
  if (any(lines < min(s$wavelength) | lines > max(s$wavelength)) || !all(covered)) {
    return(unavailable("incomplete_coverage"))
  }
  areas <- vapply(lines, function(wl) ls_peak_area(s, wl, 1), numeric(1))
  if (any(!is.finite(areas)) || areas[["Ca"]] <= 0 ||
      !any(areas[c("Na", "K", "Fe")] > 0)) {
    return(unavailable("insufficient_signal", areas))
  }
  logs <- log(areas)
  log_sum <- function(keys) {
    values <- logs[keys]
    top <- max(values)
    if (!is.finite(top)) return(-Inf)
    top + log(sum(exp(values - top)))
  }
  log_scores <- c(
    bone = unname(logs["Ca"] - log_sum(c("Na", "K", "Fe"))),
    liver = unname(logs["Fe"] - log_sum(c("Na", "K", "Ca"))),
    kidney = unname(logs["K"] - log_sum(c("Na", "Ca")) + logs["Na"] - logs["Ca"]),
    muscle = unname(logs["K"] - log_sum(c("Na", "Ca"))),
    fat = unname(logs["C"] - log_sum(c("Ca", "Fe", "K")))
  )
  scores <- exp(log_scores - max(log_scores))
  scores <- scores / sum(scores)
  list(tissue = names(scores)[which.max(scores)], score = max(scores),
       scores = scores, areas = areas, status = "heuristic")
}

#' Tissue Classification via LIBS
#'
#' Classifies tissue types based on LIBS spectral signatures. Implements
#' three methods:
#' * `"ratio"` — an unvalidated heuristic based on integrated Ca, Na, K, Fe
#'   and C line responses. It is a research illustration, not a calibrated tissue
#'   probability or clinical classifier. All required lines must be covered and
#'   the response denominators must be positive; otherwise the row is unclassified.
#' * `"plsda"` — fits a PLS-DA model on the supplied labelled `reference`
#'   dataset and predicts class for `x`.
#' * `"svm"` — fits an SVM on `reference` and predicts class.
#'
#' @param x A [ls_spectrum()] or [ls_dataset()] object (unknowns).
#' @param method Character. `"ratio"`, `"plsda"`, or `"svm"`. Default `"ratio"`.
#' @param reference A [ls_dataset()] with labelled tissue reference spectra
#'   (needed for `"plsda"` and `"svm"`).
#' @param group_col Character. Column in reference `sample_info` with tissue
#'   labels. Default `"tissue"`.
#' @param verbose Logical. Default `TRUE`.
#'
#' @return A [tibble::tibble()] with columns `sample_id`, `predicted_tissue`,
#'   `score`, `score_type`, and `status`. The former `confidence` column is
#'   replaced to distinguish relative heuristic scores, unrestricted PLS-DA
#'   scores and SVM probability estimates. None establishes tissue validity.
#'
#' @examples
#' ds <- ls_example_data("tissue")
#' ls_tissue_classify(ds[1:3])
#' @export
ls_tissue_classify <- function(x, method = "ratio", reference = NULL,
                               group_col = "tissue", verbose = TRUE) {
  method <- match.arg(method, c("ratio", "plsda", "svm"))
  .check_flag(verbose, "verbose")
  if (inherits(x, "libs_spectrum")) {
    .validate_spectrum(x)
    if (is.null(.meta_get(x$metadata, "sample_id", NULL))) x$metadata$sample_id <- "unknown"
    x <- ls_dataset(list(x))
  } else .validate_dataset(x)

  if (method == "ratio") {
    results <- lapply(x$spectra, .classify_by_ratio)
    return(tibble::tibble(
      sample_id = x$sample_info$sample_id,
      predicted_tissue = vapply(results, `[[`, character(1), "tissue"),
      score = vapply(results, `[[`, numeric(1), "score"),
      score_type = "heuristic_relative_score",
      status = vapply(results, `[[`, character(1), "status")))
  }
  if (is.null(reference)) cli::cli_abort("{.arg reference} is required for method {.val {method}}.")
  .validate_dataset(reference)
  if (!group_col %in% names(reference$sample_info)) {
    cli::cli_abort("Column {.val {group_col}} missing from {.arg reference$sample_info}.")
  }
  model <- if (method == "plsda") {
    ls_plsda(reference, grouping = group_col, n_components = 5, validation = "none")
  } else ls_train_classifier(reference, grouping = group_col, method = "svm")
  prediction <- ls_classify(model, x)
  tibble::tibble(sample_id = prediction$sample_id,
                 predicted_tissue = prediction$predicted_class,
                 score = if (method == "plsda") prediction$score else prediction$probability,
                 score_type = if (method == "plsda") "plsda_score" else "svm_probability",
                 status = "predicted")
}

#' Tissue Discrimination Analysis
#'
#' Identifies emission channels that best discriminate two tissue types via
#' per-wavelength t-tests with Benjamini-Hochberg FDR correction, plus log2
#' fold-change. Element annotations are nearest wavelength candidates, not
#' established elemental identities; `candidate_count` records ambiguity.
#' Without a configured atomic reference, statistical results remain available,
#' with missing element annotations and `annotation_status = "reference_unavailable"`.
#' A configured but unreadable or invalid reference raises an error.
#'
#' @param dataset A [ls_dataset()] with tissue labels.
#' @param group_col Character. Label column in `sample_info`.
#' @param group_a Character. First group label.
#' @param group_b Character. Second group label.
#' @param method Character. `"t_test"` (default) or `"fold_change"`.
#' @param tolerance_nm Numeric. Matching tolerance when annotating elements.
#'   Default 0.2.
#'
#' @return A [tibble::tibble()] with columns `wavelength_nm`, `mean_a`,
#'   `mean_b`, `p_value`, `fold_change`, `fdr`, `significant`, `element`.
#'
#' @examples
#' ds <- ls_example_data("tissue")
#' head(ls_tissue_discriminate(ds, "tissue", "bone", "muscle"))
#' @export
ls_tissue_discriminate <- function(dataset, group_col, group_a, group_b,
                                   method = "t_test", tolerance_nm = 0.2) {
  .validate_dataset(dataset)
  method <- match.arg(method, c("t_test", "fold_change"))
  if (!group_col %in% names(dataset$sample_info)) {
    cli::cli_abort("{.arg group_col} not found in sample_info.")
  }
  .check_number(tolerance_nm, "tolerance_nm", min = 0)
  if (length(group_a) != 1L || length(group_b) != 1L || anyNA(c(group_a, group_b)) ||
      identical(as.character(group_a), as.character(group_b))) {
    cli::cli_abort("Supply two distinct, non-missing group labels.")
  }
  labs <- as.character(dataset$sample_info[[group_col]])
  ia <- which(labs == group_a)
  ib <- which(labs == group_b)
  if (length(ia) < 2 || length(ib) < 2) {
    cli::cli_abort("Each group must have at least 2 samples.")
  }
  Xa <- dataset$intensity_matrix[ia, , drop = FALSE]
  Xb <- dataset$intensity_matrix[ib, , drop = FALSE]
  mean_a <- colMeans(Xa)
  mean_b <- colMeans(Xb)
  fc <- rep(NA_real_, length(mean_a))
  positive <- mean_a > 0 & mean_b > 0
  fc[positive] <- log2(mean_a[positive]) - log2(mean_b[positive])

  if (method == "t_test") {
    p_vals <- vapply(seq_len(ncol(Xa)), function(j) {
      tryCatch(stats::t.test(Xa[, j], Xb[, j])$p.value,
               error = function(e) NA_real_)
    }, numeric(1))
  } else {
    p_vals <- rep(NA_real_, ncol(Xa))
  }
  fdr <- if (all(is.na(p_vals))) p_vals else stats::p.adjust(p_vals, method = "BH")
  sig <- !is.na(fdr) & !is.na(fc) & fdr < 0.05 & abs(fc) > 1

  # Annotate elements
  el_db <- tryCatch(ls_element_db(), libscan_reference_missing = function(e) NULL)
  elements <- rep(NA_character_, length(dataset$wavelength))
  candidate_count <- integer(length(dataset$wavelength))
  matched <- rep(NA_real_, length(dataset$wavelength))
  for (i in if (is.null(el_db)) integer() else seq_along(dataset$wavelength)) {
    dev <- dataset$wavelength[i] - el_db$wavelength_nm
    within <- abs(dev) <= tolerance_nm
    if (!any(within)) next
    cand <- el_db[within, ]
    candidate_count[i] <- nrow(cand)
    closest <- which.min(abs(dev[within]))
    elements[i] <- cand$element[closest]
    matched[i] <- cand$wavelength_nm[closest]
  }

  out <- tibble::tibble(
    wavelength_nm = dataset$wavelength,
    mean_a = mean_a,
    mean_b = mean_b,
    p_value = p_vals,
    fold_change = fc,
    fdr = fdr,
    significant = sig,
    element = elements, candidate_count = candidate_count,
    matched_wavelength_nm = matched,
    annotation_status = if (is.null(el_db)) "reference_unavailable" else
      ifelse(is.na(elements), "no_candidate", "candidate")
  )
  out[order(out$fdr, -abs(out$fold_change)), ]
}
