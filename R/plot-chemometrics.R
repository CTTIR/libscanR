# Chemometric plots (PCA, PLS-DA)
# -----------------------------------------------------------------------------

#' Plot PCA Scores
#'
#' @param pca A `libs_pca` object from [ls_pca()].
#' @param pc_x Integer. PC for x-axis. Default 1.
#' @param pc_y Integer. PC for y-axis. Default 2.
#' @param color_by Character. Sample-info column. Numeric values use a continuous
#'   colour scale; other values define discrete groups. Default `NULL`.
#' @param ellipses Logical. Draw nominal 95% normal-theory data ellipses for
#'   discrete groups with at least four non-collinear points. They describe score
#'   dispersion, not confidence intervals for a group mean. Default `TRUE`.
#'
#' @return A ggplot2 object.
#'
#' @examples
#' ds <- ls_example_data("tissue")
#' pca <- ls_pca(ds, n_components = 4)
#' ls_plot_pca(pca, color_by = "tissue")
#' @export
ls_plot_pca <- function(pca, pc_x = 1, pc_y = 2, color_by = NULL,
                        ellipses = TRUE) {
  if (!inherits(pca, "libs_pca")) {
    cli::cli_abort("{.arg pca} must be a {.cls libs_pca} object.")
  }
  .check_number(pc_x, "pc_x", min = 1, integer = TRUE)
  .check_number(pc_y, "pc_y", min = 1, integer = TRUE)
  if (pc_x > pca$n_components || pc_y > pca$n_components) {
    cli::cli_abort("pc_x / pc_y exceed number of computed components ({pca$n_components}).")
  }
  .check_flag(ellipses, "ellipses")
  scores <- pca$scores
  df <- data.frame(
    PC_x = scores[, pc_x],
    PC_y = scores[, pc_y]
  )
  var_x <- round(pca$variance_explained[pc_x] * 100, 1)
  var_y <- round(pca$variance_explained[pc_y] * 100, 1)

  if (!is.null(color_by)) {
    if (!color_by %in% names(pca$sample_info)) {
      cli::cli_abort("{.arg color_by} column {.val {color_by}} not found.")
    }
    df$group <- pca$sample_info[[color_by]]
    numeric_colour <- is.numeric(df$group)
    if (!numeric_colour) df$group <- as.factor(df$group)
    p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$PC_x, y = .data$PC_y,
                                          colour = .data$group))
    if (ellipses && !numeric_colour) {
      eligible <- .ellipse_groups(df$PC_x, df$PC_y, df$group)
      if (any(eligible)) p <- p + ggplot2::stat_ellipse(
        data = df[eligible, , drop = FALSE], type = "norm", level = 0.95)
    }
    p <- p + ggplot2::geom_point(size = 2.5, alpha = 0.8)
    if (numeric_colour) {
      p <- p + ggplot2::scale_colour_viridis_c(name = color_by)
    } else if (nlevels(df$group) <= 9L) {
      p <- p + ggplot2::scale_colour_brewer(palette = "Set1", name = color_by)
    } else p <- p + ggplot2::scale_colour_viridis_d(name = color_by)
  } else {
    p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$PC_x, y = .data$PC_y)) +
      ggplot2::geom_point(size = 2.5, colour = "#2E86AB", alpha = 0.8)
  }
  p +
    ggplot2::labs(
      x = sprintf("PC%d (%.1f%%)", pc_x, var_x),
      y = sprintf("PC%d (%.1f%%)", pc_y, var_y),
      title = "PCA Score Plot"
    ) +
    theme_libs()
}

#' Plot PCA Loadings
#'
#' Plots the loadings for a selected principal component across the full
#' wavelength axis, optionally annotating the top contributing channels.
#'
#' @param pca A `libs_pca` object.
#' @param pc Integer. Which PC's loadings to show. Default 1.
#' @param n_top Integer. Number of top-absolute contributors to annotate.
#'   Default 10.
#'
#' @return A ggplot2 object.
#'
#' @examples
#' ds <- ls_example_data("tissue")
#' pca <- ls_pca(ds, n_components = 4)
#' ls_plot_loadings(pca, pc = 1, n_top = 5)
#' @export
ls_plot_loadings <- function(pca, pc = 1, n_top = 10) {
  if (!inherits(pca, "libs_pca")) {
    cli::cli_abort("{.arg pca} must be a {.cls libs_pca} object.")
  }
  .check_number(pc, "pc", min = 1, max = pca$n_components, integer = TRUE)
  .check_number(n_top, "n_top", min = 0, integer = TRUE)
  loadings <- pca$loadings[, pc]
  df <- data.frame(
    wavelength_nm = pca$wavelength,
    loading = loadings
  )
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$wavelength_nm,
                                        y = .data$loading)) +
    ggplot2::geom_line(colour = "#2E86AB", linewidth = 0.4) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed",
                        colour = "grey30") +
    ggplot2::labs(x = "Wavelength (nm)", y = paste0("PC", pc, " loading"),
                  title = sprintf("PC%d loadings (%.1f%% variance)",
                                  pc, pca$variance_explained[pc] * 100)) +
    theme_libs()

  if (n_top > 0) {
    top_idx <- order(abs(loadings), decreasing = TRUE)[seq_len(min(n_top,
                                                                   length(loadings)))]
    top_df <- df[top_idx, ]
    p <- p + ggplot2::geom_point(data = top_df,
                                 ggplot2::aes(x = .data$wavelength_nm,
                                              y = .data$loading),
                                 colour = "#A23B72", size = 2) +
      ggplot2::geom_text(data = top_df,
                         ggplot2::aes(x = .data$wavelength_nm,
                                      y = .data$loading,
                                      label = round(.data$wavelength_nm, 1)),
                         size = 3, vjust = -0.8, colour = "#A23B72")
  }
  p
}

#' Plot PCA Variance (Scree Plot)
#'
#' @param pca A `libs_pca` object.
#' @return A ggplot2 object.
#' @examples
#' ds <- ls_example_data("tissue")
#' pca <- ls_pca(ds, n_components = 6)
#' ls_plot_scree(pca)
#' @export
ls_plot_scree <- function(pca) {
  if (!inherits(pca, "libs_pca")) {
    cli::cli_abort("{.arg pca} must be a {.cls libs_pca} object.")
  }
  df <- data.frame(
    component = factor(paste0("PC", seq_along(pca$variance_explained)),
                       levels = paste0("PC", seq_along(pca$variance_explained))),
    variance_explained = pca$variance_explained * 100,
    cumulative = pca$cumulative_variance * 100
  )
  ggplot2::ggplot(df, ggplot2::aes(x = .data$component,
                                   y = .data$variance_explained)) +
    ggplot2::geom_col(fill = "#2E86AB", alpha = 0.8) +
    ggplot2::geom_line(ggplot2::aes(y = .data$cumulative, group = 1),
                       colour = "#A23B72", linewidth = 1) +
    ggplot2::geom_point(ggplot2::aes(y = .data$cumulative),
                        colour = "#A23B72", size = 2) +
    ggplot2::labs(x = "Component", y = "Variance explained (%)",
                  title = "Scree plot",
                  subtitle = "Bars: per-PC  |  Line: cumulative") +
    theme_libs()
}

#' Plot PLS-DA Results
#'
#' @param plsda A `libs_plsda` object from [ls_plsda()].
#' @param type Character. `"scores"` (LV1 vs LV2), `"confusion"` (heatmap),
#'   or `"vip"` (VIP scores spectrum). Default `"scores"`.
#'
#' @return A ggplot2 object.
#'
#' @examples
#' ds <- ls_example_data("tissue")
#' \donttest{
#' if (requireNamespace("pls", quietly = TRUE)) {
#'   plsda <- ls_plsda(ds, "tissue", n_components = 3, validation = "none")
#'   ls_plot_plsda(plsda, type = "scores")
#' }
#' }
#' @export
ls_plot_plsda <- function(plsda, type = "scores") {
  if (!inherits(plsda, "libs_plsda")) {
    cli::cli_abort("{.arg plsda} must be a {.cls libs_plsda} object.")
  }
  type <- match.arg(type, c("scores", "confusion", "vip"))
  basis <- .evaluation_label(plsda[["evaluation_basis"]])

  if (type == "scores") {
    scores <- plsda$model$scores[, 1:min(2, ncol(plsda$model$scores)),
                                 drop = FALSE]
    df <- data.frame(
      LV1 = scores[, 1],
      LV2 = if (ncol(scores) >= 2) scores[, 2] else rep(0, nrow(scores)),
      class = plsda$predictions$observed
    )
    p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$LV1, y = .data$LV2,
                                          colour = .data$class)) +
      ggplot2::geom_point(size = 2.5, alpha = 0.8)
    eligible <- .ellipse_groups(df$LV1, df$LV2, df$class)
    if (any(eligible)) p <- p + ggplot2::stat_ellipse(
      data = df[eligible, , drop = FALSE], type = "norm", level = 0.95)
    p <- if (length(unique(df$class)) <= 9L) {
      p + ggplot2::scale_colour_brewer(palette = "Set1")
    } else p + ggplot2::scale_colour_viridis_d()
    return(p + ggplot2::labs(x = "LV1", y = "LV2", title = "PLS-DA training scores",
                             subtitle = sprintf("%s accuracy: %.1f%%", basis, plsda$accuracy * 100)) +
             theme_libs())
  }
  if (type == "confusion") {
    cm <- plsda$confusion_matrix
    df <- as.data.frame(cm)
    names(df) <- c("observed", "predicted", "count")
    return(ggplot2::ggplot(df, ggplot2::aes(x = .data$predicted,
                                            y = .data$observed,
                                            fill = .data$count)) +
             ggplot2::geom_tile() +
             ggplot2::geom_text(ggplot2::aes(label = .data$count),
                                colour = "white") +
             ggplot2::scale_fill_viridis_c(option = "viridis") +
             ggplot2::labs(x = "Predicted", y = "Observed",
                           title = "Confusion matrix",
                           subtitle = sprintf("%s accuracy: %.1f%%", basis, plsda$accuracy * 100)) +
             theme_libs())
  }
  # VIP
  vip <- .vip_scores(plsda$model, plsda$n_components)
  wl <- plsda[["feature_contract"]][["wavelength"]]
  known_axis <- is.numeric(wl) && length(wl) == length(vip)
  df <- data.frame(wavelength_idx = if (known_axis) wl else seq_along(vip), vip = vip)
  ggplot2::ggplot(df, ggplot2::aes(x = .data$wavelength_idx,
                                   y = .data$vip)) +
    ggplot2::geom_line(colour = "#2E86AB") +
    ggplot2::geom_hline(yintercept = 1, linetype = "dashed",
                        colour = "red") +
    ggplot2::labs(x = if (known_axis) "Wavelength (nm)" else "Wavelength channel", y = "VIP score",
                  title = "Variable Importance in Projection") +
    theme_libs()
}

# VIP scores for PLS models
#' @keywords internal
#' @noRd
.vip_scores <- function(object, ncomp) {
  W <- object$loading.weights
  Q <- object$Yloadings
  TT <- object$scores
  if (!is.matrix(W) || !is.matrix(Q) || !is.matrix(TT)) {
    cli::cli_abort("VIP requires fitted weights, response loadings and scores.")
  }
  .check_number(ncomp, "ncomp", min = 1, max = min(ncol(W), ncol(Q), ncol(TT)), integer = TRUE)
  idx <- seq_len(ncomp)
  energy <- colSums(Q[, idx, drop = FALSE]^2) * colSums(TT[, idx, drop = FALSE]^2)
  norms <- colSums(W[, idx, drop = FALSE]^2)
  if (any(!is.finite(energy)) || any(!is.finite(norms)) ||
      !is.finite(sum(energy)) || sum(energy) <= 0 || any(norms[energy > 0] <= 0)) {
    cli::cli_abort("VIP is undefined without finite, positive modeled response variation and weights.")
  }
  active <- energy > 0
  contributions <- sweep(W[, idx[active], drop = FALSE]^2, 2L, norms[active], "/")
  as.numeric(sqrt(nrow(W) * (contributions %*% energy[active]) / sum(energy)))
}

.ellipse_groups <- function(x, y, group) {
  valid <- is.finite(x) & is.finite(y) & !is.na(group)
  result <- rep(FALSE, length(x))
  for (g in unique(as.character(group[valid]))) {
    idx <- which(valid & as.character(group) == g)
    xy <- cbind(x[idx], y[idx])
    if (length(idx) >= 4L && qr(scale(xy, center = TRUE, scale = FALSE))$rank == 2L) {
      result[idx] <- TRUE
    }
  }
  result
}

.evaluation_label <- function(basis) {
  switch(if (is.null(basis)) "unknown" else basis,
         cross_validation = "Cross-validated", leave_one_out = "Leave-one-out",
         training = "Training", out_of_bag = "Out-of-bag", "Unspecified evaluation")
}
