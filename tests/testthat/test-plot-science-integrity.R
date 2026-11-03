test_that("numeric PCA colors remain continuous without per-value ellipses", {
  ds <- ls_dataset(lapply(1:12, function(i) {
    ls_spectrum(c(500, 501, 502), c(sin(i), cos(i), i / 10),
                list(sample_id = paste0("s", i)))
  }), data.frame(sample_id = paste0("s", 1:12), concentration = 1:12))
  pca <- ls_pca(ds, n_components = 2)
  original <- pca
  plot <- ls_plot_pca(pca, color_by = "concentration")
  expect_no_condition(built <- ggplot2::ggplot_build(plot))
  expect_false(plot$scales$get_scales("colour")$is_discrete())
  expect_equal(nrow(built$data[[1]]), 12)
  expect_gt(length(unique(built$data[[1]]$colour)), 9)
  expect_identical(pca, original)
  expect_error(ls_plot_pca(pca, pc_x = 1.5), "integer")
})

test_that("PLS plots label the actual evaluation basis and trained wavelength axis", {
  fit <- list(scores = matrix(1:12, 6, 2), loading.weights = diag(2),
              Yloadings = matrix(c(1, 2), 1, 2))
  model <- structure(list(model = fit, n_components = 2,
    accuracy = .5, evaluation_basis = "cross_validation",
    predictions = data.frame(observed = rep(c("A", "B"), each = 3)),
    confusion_matrix = table(observed = c("A", "A", "B", "B"),
                              predicted = c("A", "B", "A", "B")),
    feature_contract = list(wavelength = c(500, 600))), class = "libs_plsda")
  scores <- ls_plot_plsda(model, "scores")
  expect_match(scores$labels$title, "training scores")
  expect_match(scores$labels$subtitle, "Cross-validated accuracy: 50")
  expect_no_condition(ggplot2::ggplot_build(scores))
  expect_match(ls_plot_plsda(model, "confusion")$labels$subtitle, "Cross-validated")
  expect_equal(ls_plot_plsda(model, "vip")$data$wavelength_idx, c(500, 600))
})

test_that("VIP agrees with independent response-energy weights and rejects zero energy", {
  model <- list(loading.weights = diag(2), Yloadings = matrix(c(1, 2), 1, 2),
                scores = diag(2))
  expect_equal(.vip_scores(model, 2), sqrt(c(.4, 1.6)), tolerance = 1e-12)
  model$Yloadings[] <- 0
  expect_error(.vip_scores(model, 2), "undefined")
})
