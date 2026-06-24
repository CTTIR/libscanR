# Additional tests for R/tissue.R ---------------------------------------------

test_that("ls_tissue_classify plsda and svm methods run", {
  ds <- ls_example_data("tissue", n_channels = 64)

  skip_if_not_installed("pls")
  out_pls <- ls_tissue_classify(ds, method = "plsda", reference = ds,
                                group_col = "tissue", verbose = FALSE)
  expect_s3_class(out_pls, "tbl_df")
  expect_true(all(c("sample_id", "predicted_tissue", "confidence") %in%
                    names(out_pls)))

  skip_if_not_installed("e1071")
  out_svm <- ls_tissue_classify(ds, method = "svm", reference = ds,
                                group_col = "tissue", verbose = FALSE)
  expect_s3_class(out_svm, "tbl_df")
})

test_that("ls_tissue_classify validates reference and group column", {
  ds <- ls_example_data("tissue", n_channels = 64)
  expect_error(ls_tissue_classify(ds, method = "plsda"), "reference")
  expect_error(
    ls_tissue_classify(ds, method = "plsda", reference = ds,
                       group_col = "nope"),
    "missing"
  )
})

test_that("ls_tissue_discriminate validates and supports fold_change", {
  ds <- ls_example_data("tissue", n_channels = 64)
  expect_error(ls_tissue_discriminate(ds, "nope", "bone", "muscle"),
               "not found")

  res <- ls_tissue_discriminate(ds, "tissue", "bone", "muscle",
                                method = "fold_change")
  expect_s3_class(res, "tbl_df")
  expect_true("fold_change" %in% names(res))
})

test_that("ls_tissue_discriminate errors with too-few samples per group", {
  ds <- ls_example_data("tissue", n_channels = 64)
  small <- ds[c(1, 11)]  # one bone, one liver
  expect_error(
    ls_tissue_discriminate(small, "tissue", "bone", "liver"),
    "at least 2 samples"
  )
})
