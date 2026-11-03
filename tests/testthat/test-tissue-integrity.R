.tissue_ratio_fixture <- function(gain = 1) {
  centres <- c(Ca = 393.37, Na = 589, K = 766.49, Fe = 371.99, C = 247.86)
  areas <- c(Ca = 100, Na = 10, K = 20, Fe = 5, C = 3)
  ls_spectrum(as.vector(rbind(centres - .01, centres, centres + .01)),
               as.vector(rbind(rep(0, 5), gain * areas / .01, rep(0, 5))))
}

test_that("ratio heuristic is scale invariant and never invents missing evidence", {
  original <- .tissue_ratio_fixture()
  before <- original
  normal <- ls_tissue_classify(original, verbose = FALSE)
  tiny <- ls_tissue_classify(.tissue_ratio_fixture(1e-12), verbose = FALSE)
  expected <- c(100 / 35, 5 / 130, 20 / 110 * 10 / 100, 20 / 110, 3 / 125)
  expect_equal(normal$predicted_tissue, "bone")
  expect_equal(normal$score, max(expected / sum(expected)), tolerance = 1e-10)
  expect_equal(tiny$predicted_tissue, normal$predicted_tissue)
  expect_equal(tiny$score, normal$score, tolerance = 1e-12)
  expect_identical(normal$score_type, "heuristic_relative_score")
  expect_identical(original, before)
  missing <- ls_tissue_classify(ls_spectrum(c(499, 500, 501), c(0, 0, 0)))
  expect_true(is.na(missing$predicted_tissue))
  expect_identical(missing$status, "incomplete_coverage")
  zero <- ls_tissue_classify(.tissue_ratio_fixture(0))
  expect_true(is.na(zero$predicted_tissue))
  expect_true(is.na(zero$score))
  expect_identical(zero$status, "insufficient_signal")
})

.tissue_contrast_fixture <- function(gain = 1, offset = 0) {
  ls_dataset(lapply(1:4, function(i) {
    ls_spectrum(c(500, 501), gain * c(2, 4) * c(1, 2, .5, 1)[i] + offset,
                list(sample_id = paste0("s", i)))
  }), data.frame(sample_id = paste0("s", 1:4), group = c("A", "A", "B", "B")))
}

test_that("reported log fold change has no hidden unit-dependent pseudocount", {
  first <- ls_tissue_discriminate(.tissue_contrast_fixture(), "group", "A", "B")
  scaled <- ls_tissue_discriminate(.tissue_contrast_fixture(10), "group", "A", "B")
  expect_equal(first$fold_change, c(1, 1), tolerance = 1e-12)
  expect_equal(scaled$fold_change, first$fold_change, tolerance = 1e-12)
  expect_equal(scaled$p_value, first$p_value, tolerance = 1e-12)
  signed <- ls_tissue_discriminate(.tissue_contrast_fixture(offset = -100), "group", "A", "B")
  expect_true(all(is.na(signed$fold_change)))
  expect_false(any(signed$significant))
  expect_error(ls_tissue_discriminate(.tissue_contrast_fixture(), "group", "A", "A"), "distinct")
})

test_that("wavelength annotation retains unknown rates and reports ambiguity", {
  local_mocked_bindings(ls_element_db = function(...) {
    tibble::tibble(wavelength_nm = c(500, 500.1, 501),
                    element = c("X", "Y", "Z"), aki = c(NA_real_, 100, NA_real_))
  })
  result <- ls_tissue_discriminate(.tissue_contrast_fixture(), "group", "A", "B")
  result <- result[order(result$wavelength_nm), ]
  expect_identical(result$element, c("X", "Z"))
  expect_identical(result$candidate_count, c(2L, 1L))
  expect_equal(result$matched_wavelength_nm, c(500, 501))
})

test_that("a missing local line cannot borrow unrelated channels inside a broad range", {
  complete <- .tissue_ratio_fixture()
  keep <- abs(complete$wavelength - 393.37) > 1
  gap <- ls_spectrum(complete$wavelength[keep], complete$intensity[, keep, drop = FALSE])
  result <- ls_tissue_classify(gap)
  expect_true(is.na(result$predicted_tissue))
  expect_true(is.na(result$score))
  expect_identical(result$status, "incomplete_coverage")
})
