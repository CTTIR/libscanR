# Additional tests for R/chemometrics.R uncovered branches --------------------

test_that("ls_pca without scaling still works and prints", {
  ds <- ls_example_data("tissue", n_channels = 64)
  pca <- ls_pca(ds, n_components = 3, scale = FALSE, center = TRUE)
  expect_s3_class(pca, "libs_pca")
  expect_message(print(pca), "libs_pca")
})

test_that("ls_plsda errors on missing grouping column and <2 classes", {
  skip_if_not_installed("pls")
  ds <- ls_example_data("tissue", n_channels = 64)
  expect_error(ls_plsda(ds, grouping = "nope"), "not found")

  one <- ds[1:5]  # all 'bone' -> single class
  expect_error(ls_plsda(one, grouping = "tissue"), "at least 2 classes")
})

test_that("ls_plsda CV validation path runs and prints", {
  skip_if_not_installed("pls")
  ds <- ls_example_data("tissue", n_channels = 64)
  cv <- ls_plsda(ds, "tissue", n_components = 2, validation = "CV")
  expect_s3_class(cv, "libs_plsda")
  expect_message(print(cv), "libs_plsda")
})

test_that("ls_cluster dbscan path runs (or errors without pkg) and prints", {
  ds <- ls_example_data("tissue", n_channels = 64)[1:20]
  if (requireNamespace("dbscan", quietly = TRUE)) {
    cl <- ls_cluster(ds, method = "dbscan", eps = 50, minPts = 2)
    expect_s3_class(cl, "libs_clusters")
    expect_message(print(cl), "libs_clusters")
  } else {
    expect_error(ls_cluster(ds, method = "dbscan"), "dbscan")
  }
})

test_that("ls_train_classifier rf path runs and predicts via ls_classify", {
  skip_if_not_installed("ranger")
  ds <- ls_example_data("tissue", n_channels = 64)
  clf <- ls_train_classifier(ds, "tissue", method = "rf")
  expect_s3_class(clf, "libs_classifier")
  expect_message(print(clf), "libs_classifier")
  pred <- ls_classify(clf, ds[1:5])
  expect_s3_class(pred, "tbl_df")
  expect_true(all(c("sample_id", "predicted_class", "probability") %in% names(pred)))
})

test_that("ls_train_classifier errors on missing grouping", {
  ds <- ls_example_data("tissue", n_channels = 64)
  expect_error(ls_train_classifier(ds, "nope"), "not found")
})

test_that("ls_classify dispatches plsda and svm, errors on bad model", {
  skip_if_not_installed("pls")
  ds <- ls_example_data("tissue", n_channels = 64)
  plsda <- ls_plsda(ds, "tissue", n_components = 2, validation = "none")
  p1 <- ls_classify(plsda, ds[1:5])
  expect_s3_class(p1, "tbl_df")

  if (requireNamespace("e1071", quietly = TRUE)) {
    svm <- ls_train_classifier(ds, "tissue", method = "svm")
    p2 <- ls_classify(svm, ds[1:5])
    expect_s3_class(p2, "tbl_df")
  }

  expect_error(ls_classify(structure(list(), class = "foo"), ds[1:2]),
               "Unsupported model class")
})

test_that(".silhouette_score handles tiny inputs", {
  d <- stats::dist(matrix(rnorm(20), nrow = 2))
  expect_true(is.na(.silhouette_score(d, c(1, 2))))
})
