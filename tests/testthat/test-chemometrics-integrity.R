chemometric_dataset <- function(X, labels = rep(c("A", "B"), length.out = nrow(X)),
                               wavelength = seq(400, 420, length.out = ncol(X)),
                               processing = list()) {
  ids <- paste0("synthetic_", seq_len(nrow(X)))
  spectra <- lapply(seq_len(nrow(X)), function(i) {
    ls_spectrum(wavelength, X[i, ],
                metadata = list(sample_id = ids[i], processing = processing))
  })
  ls_dataset(spectra, data.frame(sample_id = ids, group = labels))
}

test_that("PLS-DA CV reports held-out performance instead of fitted accuracy", {
  skip_if_not_installed("pls")
  set.seed(761)
  ds <- chemometric_dataset(matrix(rnorm(12 * 20) + 10, 12, 20))
  fit <- ls_plsda(ds, "group", n_components = 8, validation = "CV")
  training <- predict(fit$model, ncomp = fit$n_components)[, , 1]
  training_class <- fit$class_labels[max.col(training, ties.method = "first")]
  expect_equal(mean(training_class == ds$sample_info$group), 1)
  expect_lt(fit$accuracy, 0.8)
  expect_identical(fit$evaluation_basis, "cross_validation")

  # Independently refit each actual held-out fold, never using its responses.
  expected <- character(ds$n_spectra)
  for (held_out in fit$model$validation$segments) {
    rows <- setdiff(seq_len(ds$n_spectra), held_out)
    Y <- stats::model.matrix(~ factor(ds$sample_info$group) - 1)
    df <- data.frame(Y = I(Y[rows, , drop = FALSE]))
    df$X <- ds$intensity_matrix[rows, , drop = FALSE]
    refit <- pls::plsr(Y ~ X, data = df, ncomp = fit$n_components,
                       validation = "none")
    scores <- predict(refit, newdata = ds$intensity_matrix[held_out, , drop = FALSE],
                      ncomp = fit$n_components)
    scores <- matrix(scores, nrow = length(held_out), ncol = 2)
    expected[held_out] <- fit$class_labels[max.col(scores, ties.method = "first")]
  }
  expect_identical(fit$predictions$predicted, expected)
  expect_equal(fit$accuracy, mean(expected == ds$sample_info$group))
  expect_equal(dim(fit$confusion_matrix), c(2L, 2L))
  expect_equal(unname(rowSums(fit$confusion_matrix)), c(6, 6))
})

test_that("PLS-DA LOO and fitted evaluation have explicit distinct bases", {
  skip_if_not_installed("pls")
  set.seed(19)
  ds <- chemometric_dataset(matrix(rnorm(8 * 5) + 10, 8, 5))
  loo <- ls_plsda(ds, "group", n_components = 2, validation = "LOO")
  expect_identical(loo$evaluation_basis, "leave_one_out")
  expect_equal(lengths(loo$model$validation$segments), rep(1L, 8))
  scores <- loo$model$validation$pred[, , loo$n_components]
  expect_equal(loo$predictions$predicted,
               loo$class_labels[max.col(scores, ties.method = "first")])
  fitted <- ls_plsda(ds, "group", n_components = 2, validation = "none")
  expect_identical(fitted$evaluation_basis, "training")
  single <- ls_classify(fitted, ds[1])
  expect_equal(nrow(single), 1L)
  expect_named(single, c("sample_id", "predicted_class", "score"))
  expect_true(is.finite(single$score))
})

test_that("component counts and fold feature rank are validated", {
  skip_if_not_installed("pls")
  ds <- chemometric_dataset(outer(seq_len(8), c(1, 2, 3, 4)))
  for (n in list(0, -1, 1.5, NA_real_, Inf, c(1, 2), TRUE)) {
    expect_error(ls_plsda(ds, "group", n_components = n), "n_components")
    expect_error(ls_pca(ds, n_components = n), "n_components")
  }
  fit <- ls_plsda(ds, "group", n_components = 50, validation = "LOO")
  expect_equal(fit$n_components, 1)
  expect_equal(dim(fit$model$validation$pred)[3], 1)
  expect_true(is.finite(fit$accuracy))
  expect_error(ls_plsda(ds[1:2], "group", validation = "LOO"), "training fold")
  constant <- chemometric_dataset(matrix(10, 8, 4))
  expect_error(ls_plsda(constant, "group"), "varying")
  expect_error(ls_pca(constant), "varying")
  expect_error(ls_pca(constant, scale = FALSE), "varying")
  expect_error(ls_pca(ds[1]), "two spectra")
  expect_error(ls_pca(ds, scale = 1), "scale")
})

test_that("class labels are complete and square class tables retain empty columns", {
  skip_if_not_installed("pls")
  ds <- chemometric_dataset(outer(seq_len(8), c(1, 2, 3, 4)))
  for (bad in list(c(NA, rep("A", 7)), c("", rep("A", 7)),
                   c(Inf, rep(1, 7)), c(NaN, rep(1, 7)))) {
    ds$sample_info$group <- bad
    expect_error(ls_plsda(ds, "group"), "labels")
    expect_error(ls_train_classifier(ds, "group"), "labels")
  }
  ds$sample_info$group <- factor(rep("A", 8), levels = c("A", "unused"))
  expect_error(ls_plsda(ds, "group"), "at least 2 classes")
  cm <- .classification_table(c("A", "B"), c("A", "A"), c("A", "B"))
  expect_equal(dim(cm), c(2L, 2L))
  expect_equal(unname(cm[, "B"]), c(0L, 0L))
})

test_that("classifiers reject shifted axes and different preprocessing", {
  skip_if_not_installed("pls")
  set.seed(88)
  X <- matrix(rnorm(12 * 6) + 10, 12, 6)
  ds <- chemometric_dataset(X)
  fit <- ls_plsda(ds, "group", n_components = 2, validation = "none")
  expect_identical(fit$feature_contract$schema_version, 1L)
  shifted <- chemometric_dataset(X, wavelength = ds$wavelength + 0.001)
  expect_error(ls_classify(fit, shifted), "wavelength axis")
  transformed <- chemometric_dataset(X, processing = list(
    list(operation = "normalize", parameters = list(method = "area"))))
  expect_error(ls_classify(fit, transformed), "preprocessing")
  old <- fit
  old$feature_contract <- NULL
  expect_error(ls_classify(old, ds), "refit")
  expect_equal(nrow(ls_classify(fit, ds[1])), 1L)

  if (requireNamespace("e1071", quietly = TRUE)) {
    svm <- ls_train_classifier(ds, "group", method = "svm")
    expect_identical(svm$evaluation_basis, "training")
    expect_equal(dim(svm$confusion_matrix), c(2L, 2L))
    expect_error(ls_classify(svm, shifted), "wavelength axis")
    expect_equal(nrow(ls_classify(svm, ds[1])), 1L)
  }
  if (requireNamespace("ranger", quietly = TRUE)) {
    rf <- ls_train_classifier(ds, "group", method = "rf", num.trees = 100,
                              seed = 71, num.threads = 1)
    expect_identical(rf$evaluation_basis, "out_of_bag")
    expected <- colnames(rf$model$predictions)[max.col(rf$model$predictions,
                                                     ties.method = "first")]
    expect_equal(rf$accuracy, mean(expected == ds$sample_info$group))
    expect_error(ls_classify(rf, shifted), "wavelength axis")
    expect_equal(nrow(ls_classify(rf, ds[1])), 1L)
    expect_error(ls_train_classifier(ds, "group", method = "rf",
                                     num.trees = 1, seed = 71, num.threads = 1),
                 "out-of-bag predictions are incomplete")
  }
})

test_that("silhouette assigns zero to singleton clusters and excludes noise", {
  locations <- matrix(c(0, 1, 10), ncol = 1)
  # s(0) = (10-1)/10, s(1) = (9-1)/9, and the singleton contributes zero.
  expected <- ((10 - 1) / 10 + (9 - 1) / 9 + 0) / 3
  expect_equal(.silhouette_score(dist(locations), c(1, 1, 2)), expected)
  expect_equal(.silhouette_score(dist(locations * 1e-15), c(1, 1, 2)), expected)
  with_noise <- rbind(locations, 1.1)
  expect_equal(.silhouette_score(dist(with_noise), c(1, 1, 2, 0)), expected)
  expect_true(is.na(.silhouette_score(dist(locations), c(1, 1, 0))))
  expect_equal(.silhouette_score(dist(matrix(0, 3, 1)), c(1, 1, 2)), 0)
})

test_that("DBSCAN public summary leaves unassigned noise out of silhouette", {
  skip_if_not_installed("dbscan")
  locations <- c(0, 0.1, 0.2, 5, 5.1, 5.2, 20)
  ds <- chemometric_dataset(cbind(locations, 2 * locations))
  result <- ls_cluster(ds, method = "dbscan", eps = 0.1, minPts = 2)
  expect_equal(result$k, 2L)
  expect_equal(result$cluster[7], 0L)
  # Each three-point cluster has within means .15/.1/.15; the other
  # cluster's means are 5.1/5/4.9. Scaling both coordinates cancels.
  expected <- mean((c(5.1, 5, 4.9) - c(0.15, 0.1, 0.15)) / c(5.1, 5, 4.9))
  expect_equal(result$silhouette, expected)
})


test_that("SVM training summary uses the same decision rule as classification", {
  skip_if_not_installed("e1071")
  set.seed(1)
  ds <- chemometric_dataset(matrix(rnorm(30 * 4) + 10, 30, 4),
                             labels = rep(c("A", "B", "C"), 10))
  fit <- ls_train_classifier(ds, "group", method = "svm", cost = 10, gamma = 0.5)
  prediction <- ls_classify(fit, ds)
  voting <- predict(fit$model, data.frame(ds$intensity_matrix), probability = FALSE)
  # Actual libsvm probability-based decisions can differ from pairwise voting.
  expect_true(any(as.character(voting) != prediction$predicted_class))
  expect_identical(fit$predictions$predicted, prediction$predicted_class)
  expect_equal(fit$accuracy, mean(prediction$predicted_class == ds$sample_info$group))
  raw <- predict(fit$model, data.frame(ds$intensity_matrix), probability = TRUE)
  probabilities <- attr(raw, "probabilities")
  expected <- probabilities[cbind(seq_len(nrow(probabilities)),
                                  match(prediction$predicted_class, colnames(probabilities)))]
  expect_equal(unname(prediction$probability), unname(expected))
})


test_that("clustering rejects invalid k and overflow while retaining constant channels", {
  ds <- chemometric_dataset(cbind(c(1, 2, 8, 9), rep(10, 4)))
  for (method in c("kmeans", "hclust")) {
    for (k in list(0, -1, 1.5, NA_real_, Inf, c(1, 2), TRUE, 5)) {
      expect_error(ls_cluster(ds, method = method, k = k), "k.*finite integer")
    }
    result <- ls_cluster(ds, method = method, k = 2)
    expect_equal(length(unique(result$cluster)), 2L)
    expect_true(is.finite(result$silhouette))
    extreme <- chemometric_dataset(cbind(c(-1e308, 1e308, -1e308, 1e308), rep(10, 4)))
    expect_error(ls_cluster(extreme, method = method, k = 1), "overflow")
  }
  expect_error(ls_cluster(ds[1]), "two spectra")
  local_mocked_bindings(.silhouette_score = function(...) stop("unexpected silhouette failure"))
  expect_error(ls_cluster(ds, method = "hclust", k = 2), "unexpected silhouette failure")
})
