# Chemometrics: PCA, PLS-DA, clustering, classifiers
# -----------------------------------------------------------------------------

#' Principal Component Analysis of LIBS Spectra
#'
#' Performs PCA on the intensity matrix of a [ls_dataset()].
#'
#' @param dataset A [ls_dataset()] object.
#' @param n_components Integer. Number of PCs to retain. Default 10.
#' @param scale Logical. Scale variables to unit variance. Default `TRUE`.
#' @param center Logical. Center variables. Default `TRUE`.
#'
#' @return A list with S3 class `libs_pca` containing:
#'   `scores` (matrix: spectra x PCs), `loadings` (matrix: channels x PCs),
#'   `sdev`, `variance_explained` (fraction), `cumulative_variance`,
#'   `wavelength`, `sample_info`, `pca_obj`.
#'
#' @examples
#' ds <- ls_example_data("tissue")
#' pca <- ls_pca(ds, n_components = 5)
#' pca$variance_explained
#'
#' @export
ls_pca <- function(dataset, n_components = 10, scale = TRUE, center = TRUE) {
  .validate_dataset(dataset)
  .check_number(n_components, "n_components", min = 1, integer = TRUE)
  .check_flag(scale, "scale")
  .check_flag(center, "center")
  X <- dataset$intensity_matrix
  if (nrow(X) < 2L) cli::cli_abort("PCA requires at least two spectra.")
  col_sds <- apply(X, 2, stats::sd)
  if (any(!is.finite(col_sds)) || !any(col_sds > 0)) {
    cli::cli_abort("PCA requires finite, varying spectral features.")
  }
  # Remove zero-variance columns if scale=TRUE to avoid errors
  if (isTRUE(scale)) {
    nonzero <- col_sds > 0
    if (!all(nonzero)) {
      X <- X[, nonzero, drop = FALSE]
      wl_used <- dataset$wavelength[nonzero]
    } else {
      wl_used <- dataset$wavelength
    }
  } else {
    wl_used <- dataset$wavelength
  }
  pca <- stats::prcomp(X, center = center, scale. = scale)
  n_components <- min(n_components, ncol(pca$x))
  if (any(!is.finite(pca$x)) || any(!is.finite(pca$sdev)) ||
      !any(pca$sdev > 0)) {
    cli::cli_abort("PCA is numerically degenerate; rescale the spectral features.")
  }
  relative_variance <- (pca$sdev / max(pca$sdev))^2
  var_expl <- relative_variance / sum(relative_variance)

  # Pad loadings back to full wavelength axis
  full_loadings <- matrix(0,
                          nrow = dataset$n_channels,
                          ncol = n_components)
  if (length(wl_used) != dataset$n_channels) {
    idx_full <- match(wl_used, dataset$wavelength)
    full_loadings[idx_full, ] <- pca$rotation[, seq_len(n_components), drop = FALSE]
  } else {
    full_loadings <- pca$rotation[, seq_len(n_components), drop = FALSE]
  }

  structure(
    list(
      scores = pca$x[, seq_len(n_components), drop = FALSE],
      loadings = full_loadings,
      sdev = pca$sdev[seq_len(n_components)],
      variance_explained = var_expl[seq_len(n_components)],
      cumulative_variance = cumsum(var_expl)[seq_len(n_components)],
      wavelength = dataset$wavelength,
      sample_info = dataset$sample_info,
      n_components = n_components,
      pca_obj = pca
    ),
    class = "libs_pca"
  )
}

#' @export
print.libs_pca <- function(x, ...) {
  cli::cli_inform(c(
    "{.cls libs_pca}",
    "*" = "Components: {x$n_components}",
    "*" = "Spectra: {nrow(x$scores)}",
    "*" = "Variance (first 3): {paste(round(x$variance_explained[seq_len(min(3, x$n_components))] * 100, 1), collapse = ', ')}%",
    "*" = "Cumulative (first 3): {round(x$cumulative_variance[min(3, x$n_components)] * 100, 1)}%"
  ))
  invisible(x)
}

#' PLS-DA Classification
#'
#' Partial Least Squares Discriminant Analysis for class prediction.
#'
#' @param dataset A [ls_dataset()] object.
#' @param grouping Character. Column name in `sample_info` with class labels.
#' @param n_components Integer. Number of PLS latent variables. Default 5.
#' @param validation Character. `"CV"` (10-fold), `"LOO"`, or `"none"`.
#'   Default `"CV"`. Accuracy and predictions use held-out predictions for
#'   CV/LOO and fitted predictions only for `"none"`. Components are capped at
#'   the centered feature rank and training-sample bound of every fold.
#'   Every training fold must retain at least two classes. These sample-level
#'   folds do not establish patient/site-level generalization.
#'
#' @return An S3 object of class `libs_plsda` with elements `model`,
#'   `predictions` (tibble with predicted/observed class), `confusion_matrix`,
#'   `accuracy`, `class_labels`, `n_components`, `sample_info`,
#'   `feature_contract`, and `evaluation_basis` (`"cross_validation"`,
#'   `"leave_one_out"`, or `"training"`).
#'
#' @examples
#' ds <- ls_example_data("tissue")
#' \donttest{
#' if (requireNamespace("pls", quietly = TRUE)) {
#'   plsda <- ls_plsda(ds, "tissue", n_components = 3, validation = "none")
#'   plsda$accuracy
#' }
#' }
#' @export
ls_plsda <- function(dataset, grouping, n_components = 5, validation = "CV") {
  .validate_dataset(dataset)
  .require_pkg("pls", "PLS-DA requires the {.pkg pls} package.")
  validation <- match.arg(validation, c("CV", "LOO", "none"))

  .check_number(n_components, "n_components", min = 1, integer = TRUE)
  labels <- .classification_labels(dataset, grouping)
  class_labels <- levels(labels)
  contract <- .spectral_feature_contract(dataset)
  Y <- stats::model.matrix(~ labels - 1)
  colnames(Y) <- class_labels
  X <- dataset$intensity_matrix

  segments <- switch(validation,
    CV = pls::cvsegments(nrow(X), k = min(10L, nrow(X))),
    LOO = as.list(seq_len(nrow(X))),
    none = list(integer())
  )
  bounds <- vapply(segments, function(held_out) {
    rows <- setdiff(seq_len(nrow(X)), held_out)
    if (length(rows) < 2L || length(unique(labels[rows])) < 2L) {
      cli::cli_abort("Every PLS training fold needs at least two spectra and two classes; revise the data or validation scheme.")
    }
    centered <- scale(X[rows, , drop = FALSE], center = TRUE, scale = FALSE)
    if (any(!is.finite(centered))) {
      cli::cli_abort("PLS features overflow when centered; rescale the input intensities.")
    }
    min(length(rows) - 1L, ncol(X), qr(centered)$rank)
  }, numeric(1))
  n_components <- min(n_components, bounds)
  if (n_components < 1L) {
    cli::cli_abort("Every PLS training fold requires varying spectral features.")
  }

  df <- data.frame(Y = I(Y))
  df$X <- X
  args <- list(formula = Y ~ X, ncomp = n_components, data = df,
               validation = validation)
  # pls supplies its own segments argument for LOO; do not supply it twice.
  if (validation == "CV") args$segments <- segments
  fit <- do.call(pls::plsr, args)
  pred_array <- if (validation == "none") {
    stats::predict(fit, ncomp = n_components)
  } else {
    fit$validation$pred[, , n_components, drop = FALSE]
  }
  pred_mat <- matrix(pred_array, nrow = nrow(X), ncol = length(class_labels))
  if (any(!is.finite(pred_mat))) {
    cli::cli_abort("PLS predictions are numerically degenerate; reduce components or revise the training data.")
  }
  pred_class <- class_labels[max.col(pred_mat, ties.method = "first")]
  obs_class <- as.character(labels)
  cm <- .classification_table(obs_class, pred_class, class_labels)
  acc <- mean(obs_class == pred_class)

  structure(
    list(
      model = fit,
      predictions = tibble::tibble(
        sample_id = dataset$sample_info$sample_id,
        observed = obs_class,
        predicted = pred_class
      ),
      confusion_matrix = cm,
      accuracy = acc,
      class_labels = class_labels,
      n_components = n_components,
      sample_info = dataset$sample_info,
      feature_contract = contract,
      evaluation_basis = switch(validation, CV = "cross_validation",
                                LOO = "leave_one_out", none = "training")
    ),
    class = "libs_plsda"
  )
}

#' @export
print.libs_plsda <- function(x, ...) {
  cli::cli_inform(c(
    "{.cls libs_plsda}",
    "*" = "Classes ({length(x$class_labels)}): {paste(x$class_labels, collapse = ', ')}",
    "*" = "Components: {x$n_components}",
    "*" = "Accuracy ({x$evaluation_basis}): {round(x$accuracy * 100, 1)}%"
  ))
  invisible(x)
}

#' Cluster LIBS Spectra
#'
#' Unsupervised clustering via k-means, hierarchical, or DBSCAN (DBSCAN
#' requires the `dbscan` package in Suggests).
#'
#' @param dataset A [ls_dataset()] object.
#' @param method Character. `"kmeans"`, `"hclust"`, or `"dbscan"`.
#'   Default `"kmeans"`.
#' @param k Integer. Number of clusters for kmeans/hclust. Default 3.
#' @param ... Additional arguments passed to the underlying clustering
#'   function.
#'
#' @return An S3 object of class `libs_clusters` with elements `cluster`,
#'   `method`, `k`, `silhouette` (mean score excluding DBSCAN noise;
#'   singleton clusters contribute zero; `NA` when not computable),
#'   `sample_info`.
#'
#' @examples
#' ds <- ls_example_data("tissue")
#' cl <- ls_cluster(ds, method = "kmeans", k = 5)
#' cl$cluster
#' @export
ls_cluster <- function(dataset, method = "kmeans", k = 3, ...) {
  .validate_dataset(dataset)
  method <- match.arg(method, c("kmeans", "hclust", "dbscan"))
  X <- dataset$intensity_matrix
  if (nrow(X) < 2L) cli::cli_abort("Clustering requires at least two spectra.")
  if (method != "dbscan") {
    .check_number(k, "k", min = 1, max = nrow(X), integer = TRUE)
  }
  # Only known constant channels become zero; overflow is not missing signal.
  centered <- sweep(X, 2L, colMeans(X), "-")
  deviations <- apply(X, 2L, stats::sd)
  if (any(!is.finite(centered)) || any(!is.finite(deviations))) {
    cli::cli_abort("Clustering features overflow during standardization; rescale the input intensities.")
  }
  varying <- deviations > 0
  X_scaled <- centered
  X_scaled[, !varying] <- 0
  X_scaled[, varying] <- sweep(centered[, varying, drop = FALSE], 2L,
                               deviations[varying], "/")
  if (any(!is.finite(X_scaled))) {
    cli::cli_abort("Clustering standardized features must be finite; rescale the input intensities.")
  }

  if (method == "kmeans") {
    km <- stats::kmeans(X_scaled, centers = k, nstart = 10, ...)
    clusters <- km$cluster
    centers <- km$centers
  } else if (method == "hclust") {
    d <- stats::dist(X_scaled)
    hc <- stats::hclust(d, method = "ward.D2")
    clusters <- stats::cutree(hc, k = k)
    centers <- NULL
  } else {
    if (!requireNamespace("dbscan", quietly = TRUE)) {
      cli::cli_abort("DBSCAN requires the {.pkg dbscan} package.")
    }
    db <- dbscan::dbscan(X_scaled, ...)
    clusters <- db$cluster
    k <- length(unique(clusters[clusters > 0]))
    centers <- NULL
  }

  sil <- NA_real_
  if (k >= 2 && length(unique(clusters)) >= 2) {
    d <- stats::dist(X_scaled)
    sil <- .silhouette_score(d, clusters)
  }

  structure(
    list(
      cluster = clusters,
      method = method,
      k = k,
      centers = centers,
      silhouette = sil,
      sample_info = dataset$sample_info
    ),
    class = "libs_clusters"
  )
}

#' @export
print.libs_clusters <- function(x, ...) {
  cli::cli_inform(c(
    "{.cls libs_clusters}",
    "*" = "Method: {.val {x$method}}",
    "*" = "k: {x$k}",
    "*" = "Silhouette: {if (is.na(x$silhouette)) 'NA' else round(x$silhouette, 3)}"
  ))
  invisible(x)
}

#' Train a Classifier
#'
#' Trains SVM or Random Forest on spectral intensity features.
#'
#' @param dataset A [ls_dataset()] with labelled samples.
#' @param grouping Character. Column name in `sample_info` with class labels.
#' @param method Character. `"svm"` or `"rf"`. Default `"svm"`.
#' @param ... Additional arguments passed to the underlying trainer.
#'
#' @return An S3 object of class `libs_classifier`, including predictions,
#'   a square confusion matrix, the fitted `feature_contract`, and
#'   `evaluation_basis`: `"training"` for SVM or `"out_of_bag"` for RF.
#'   SVM evaluation uses the same probability-based class decision as
#'   [ls_classify()]. Training accuracy is not an independent estimate of
#'   generalization.
#'
#' @examples
#' ds <- ls_example_data("tissue")
#' \donttest{
#' if (requireNamespace("e1071", quietly = TRUE)) {
#'   clf <- ls_train_classifier(ds, "tissue", method = "svm")
#'   clf$accuracy
#' }
#' }
#' @export
ls_train_classifier <- function(dataset, grouping, method = "svm", ...) {
  .validate_dataset(dataset)
  method <- match.arg(method, c("svm", "rf"))
  labels <- .classification_labels(dataset, grouping)
  contract <- .spectral_feature_contract(dataset)
  X <- dataset$intensity_matrix

  if (method == "svm") {
    .require_pkg("e1071", "SVM training requires {.pkg e1071}.")
    df <- data.frame(X)
    df$.class <- labels
    fit <- e1071::svm(.class ~ ., data = df, probability = TRUE, ...)
    pred <- stats::predict(fit, df, probability = TRUE)
    acc <- mean(pred == labels)
  } else {
    .require_pkg("ranger", "Random Forest requires {.pkg ranger}.")
    df <- data.frame(X)
    df$.class <- labels
    fit <- ranger::ranger(.class ~ ., data = df,
                          classification = TRUE,
                          probability = TRUE, ...)
    pred_probs <- fit$predictions
    if (!is.matrix(pred_probs) || any(!is.finite(pred_probs))) {
      cli::cli_abort("RF out-of-bag predictions are incomplete; increase num.trees or revise the training data.")
    }
    pred <- colnames(pred_probs)[max.col(pred_probs, ties.method = "first")]
    acc <- mean(pred == labels)
  }

  cm <- .classification_table(labels, pred, levels(labels))

  structure(
    list(
      model = fit,
      method = method,
      accuracy = acc,
      confusion_matrix = cm,
      class_labels = levels(labels),
      sample_info = dataset$sample_info,
      predictions = tibble::tibble(sample_id = dataset$sample_info$sample_id,
                                   observed = as.character(labels),
                                   predicted = as.character(pred)),
      feature_contract = contract,
      evaluation_basis = if (method == "svm") "training" else "out_of_bag"
    ),
    class = "libs_classifier"
  )
}

#' @export
print.libs_classifier <- function(x, ...) {
  cli::cli_inform(c(
    "{.cls libs_classifier}",
    "*" = "Method: {.val {x$method}}",
    "*" = "Classes ({length(x$class_labels)}): {paste(x$class_labels, collapse = ', ')}",
    "*" = "Accuracy ({x$evaluation_basis}): {round(x$accuracy * 100, 1)}%"
  ))
  invisible(x)
}

#' Classify Unknown Spectra
#'
#' Applies a trained classifier (from [ls_plsda()] or [ls_train_classifier()])
#' to new spectra.
#'
#' @param model A `libs_plsda` or `libs_classifier` object.
#' @param new_data A [ls_dataset()] of unknown spectra.
#'
#' @return A [tibble::tibble()] with columns `sample_id`, `predicted_class`,
#'   and `score` for PLS-DA (an unbounded discriminant score, not a
#'   probability), or `probability` for SVM/RF. The wavelength axis and ordered
#'   preprocessing must match the fitted contract. Legacy models without this
#'   contract must be refitted before prediction.
#'
#' @examples
#' ds <- ls_example_data("tissue")
#' \donttest{
#' if (requireNamespace("e1071", quietly = TRUE)) {
#'   clf <- ls_train_classifier(ds[1:30], "tissue", method = "svm")
#'   ls_classify(clf, ds[31:50])
#' }
#' }
#' @export
ls_classify <- function(model, new_data) {
  .validate_dataset(new_data)
  X <- new_data$intensity_matrix
  sids <- new_data$sample_info$sample_id

  if (inherits(model, "libs_plsda") || inherits(model, "libs_classifier")) {
    .assert_spectral_contract(model[["feature_contract"]], new_data)
  }
  if (inherits(model, "libs_plsda")) {
    pred_mat <- stats::predict(model$model, newdata = X, ncomp = model$n_components)
    pred_mat <- matrix(pred_mat, nrow = nrow(X), ncol = length(model$class_labels))
    if (any(!is.finite(pred_mat))) cli::cli_abort("PLS prediction produced nonfinite scores.")
    pred <- model$class_labels[max.col(pred_mat, ties.method = "first")]
    scores <- apply(pred_mat, 1, max)
    return(tibble::tibble(
      sample_id = sids,
      predicted_class = pred,
      score = scores
    ))
  }
  if (inherits(model, "libs_classifier")) {
    if (model$method == "svm") {
      df <- data.frame(X)
      pred <- stats::predict(model$model, df, probability = TRUE)
      probs <- attr(pred, "probabilities")
      prob_max <- if (is.null(probs)) rep(NA_real_, length(pred)) else apply(probs, 1, max)
      return(tibble::tibble(
        sample_id = sids,
        predicted_class = as.character(pred),
        probability = prob_max
      ))
    }
    if (model$method == "rf") {
      df <- data.frame(X)
      prd <- stats::predict(model$model, data = df)
      probs <- prd$predictions
      pred <- colnames(probs)[max.col(probs, ties.method = "first")]
      prob_max <- apply(probs, 1, max)
      return(tibble::tibble(
        sample_id = sids,
        predicted_class = pred,
        probability = prob_max
      ))
    }
  }
  cli::cli_abort("Unsupported model class: {.val {class(model)[1]}}")
}

# Silhouette score (mean across samples)
#' @keywords internal
#' @noRd
.silhouette_score <- function(d, clusters) {
  d <- as.matrix(d)
  # DBSCAN label zero is noise, not an additional cluster.
  keep <- !is.na(clusters) & clusters != 0
  clusters <- clusters[keep]
  d <- d[keep, keep, drop = FALSE]
  n <- length(clusters)
  if (n < 3 || length(unique(clusters)) < 2L) return(NA_real_)
  scores <- numeric(n)
  for (i in seq_len(n)) {
    ci <- clusters[i]
    same <- which(clusters == ci & seq_len(n) != i)
    if (!length(same)) {
      scores[i] <- 0
      next
    }
    a_i <- mean(d[i, same])
    other_clusters <- setdiff(unique(clusters), ci)
    if (length(other_clusters) == 0) {
      scores[i] <- 0
      next
    }
    b_vec <- vapply(other_clusters, function(oc) {
      mem <- which(clusters == oc)
      if (length(mem) == 0) Inf else mean(d[i, mem])
    }, numeric(1))
    b_i <- min(b_vec)
    denominator <- max(a_i, b_i)
    scores[i] <- if (denominator == 0) 0 else (b_i - a_i) / denominator
  }
  mean(scores, na.rm = TRUE)
}

# Complete labels and the same class axes for all classifier summaries.
.classification_labels <- function(dataset, grouping) {
  if (!is.character(grouping) || length(grouping) != 1L || is.na(grouping) ||
      !grouping %in% names(dataset$sample_info)) {
    cli::cli_abort("{.arg grouping} column not found in sample_info.")
  }
  labels <- dataset$sample_info[[grouping]]
  if (!(is.character(labels) || is.factor(labels) || is.numeric(labels) ||
        is.logical(labels)) || is.complex(labels) || !is.null(dim(labels)) ||
      anyNA(labels) || (is.numeric(labels) && any(!is.finite(labels))) ||
      any(!nzchar(trimws(as.character(labels))))) {
    cli::cli_abort("Class labels must be complete, finite, non-empty values.")
  }
  labels <- factor(labels)
  if (nlevels(labels) < 2L) cli::cli_abort("Need at least 2 classes; got {nlevels(labels)}.")
  labels
}

.classification_table <- function(observed, predicted, classes) {
  table(observed = factor(observed, levels = classes),
        predicted = factor(predicted, levels = classes))
}
