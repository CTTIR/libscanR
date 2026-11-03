test_that("ls_tissue_classify (ratio) returns tibble", {
  ds <- ls_example_data("tissue", n_channels = 128)[1:5]
  out <- ls_tissue_classify(ds, method = "ratio")
  expect_s3_class(out, "tbl_df")
  expect_true(all(c("sample_id", "predicted_tissue", "score", "score_type", "status") %in% names(out)))
})

test_that("ls_tissue_classify works on single spectrum", {
  s <- ls_simulate_spectrum(line_data = ls_demo_peaks(), elements = c(Ca = 200000, P = 100000),
                            seed = 1, n_channels = 256)
  out <- ls_tissue_classify(s, method = "ratio")
  expect_equal(nrow(out), 1)
})

test_that("ls_tissue_discriminate returns ranked tibble", {
  ds <- ls_example_data("tissue", n_channels = 64)
  res <- ls_tissue_discriminate(ds, "tissue", "bone", "muscle")
  expect_s3_class(res, "tbl_df")
  expect_true(all(c("wavelength_nm", "p_value", "fold_change",
                    "fdr", "significant") %in% names(res)))
})
