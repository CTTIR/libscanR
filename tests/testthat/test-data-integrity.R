test_that("wavelength sorting keeps shots and baseline attached to channels", {
  x <- ls_spectrum(c(503, 501, 502), rbind(c(30, 10, 20), c(60, 20, 40)),
                   baseline = c(300, 100, 200))
  expect_equal(x$wavelength, 501:503)
  expect_equal(x$intensity, rbind(c(10, 20, 30), c(20, 40, 60)))
  expect_equal(x$baseline, c(100, 200, 300))
  expect_equal(x[c(1, 3)]$baseline, c(100, 300))
})

test_that("invalid spectra and stale dataset caches fail before analysis", {
  for (wl in list(c(500, Inf), c(500, 500), c(0, 500), c(500, NA))) {
    expect_error(ls_spectrum(wl, c(1, 2)), "wavelength")
  }
  expect_error(ls_spectrum(500:502, array(1, c(2, 3, 2))), "two-dimensional")
  expect_error(ls_spectrum(500:502, matrix(numeric(), 0, 3)), "non-empty")
  expect_error(ls_spectrum(500:502, c(1, NA, 3)), "finite")
  expect_error(ls_spectrum(500:502, 1:3, baseline = c("a", "b", "c")), "baseline")
  expect_error(ls_spectrum(500:502, 1:3, metadata = list(1)), "names")
  s <- ls_spectrum(500:502, 1:3)
  s$n_channels <- 2L
  expect_error(ls_write_csv(s, tempfile()), "structure")
  ds <- ls_dataset(list(ls_spectrum(500:502, 1:3)))
  ds$intensity_matrix[1, 1] <- 999
  expect_error(ls_pca(ds), "stale dataset")
})

test_that("sample identities align exactly and generated identities do not collide", {
  s <- function(id) ls_spectrum(500:502, 1:3, metadata = list(sample_id = id))
  expect_error(ls_dataset(list(s("a"), s("a"))), "unique")
  expect_error(ls_dataset(list(s("a"), s("b")),
                         data.frame(sample_id = c("a", "wrong"))), "exactly once")
  expect_error(ls_dataset(list(s("a"), s("b")),
                         data.frame(sample_id = c("a", "a"))), "exactly once")
  ds <- ls_dataset(list(s(NULL), s("sample_1")))
  expect_equal(length(unique(ds$sample_info$sample_id)), 2L)
  expect_equal(ds$spectra[[2]]$metadata$sample_id, "sample_1")
  aligned <- ls_dataset(list(s("a"), s("b")),
                        data.frame(sample_id = c("b", "a"), amount = c(2, 1)))
  expect_equal(aligned$sample_info$amount, c(1, 2))
  shifted <- ls_spectrum(c(500, 501, 502.01), 1:3)
  expect_error(ls_dataset(list(s("a"), shifted)), "axes differ")
  expect_error(c(s("a"), shifted), "same wavelength")
})

test_that("combined baselines reflect all contributing shots", {
  a <- ls_spectrum(500:502, 1:3, list(sample_id = "a", material = "one"), c(1, 2, 3))
  b <- ls_spectrum(500:502, rbind(4:6, 7:9),
                   list(sample_id = "b", material = "two"), c(4, 5, 6))
  combined <- c(a, b)
  expect_equal(combined$baseline, c(3, 4, 5))
  expect_null(combined$metadata$sample_id)
  expect_null(combined$metadata$material)
  expect_equal(combined$metadata$combined_metadata[[2]], b$metadata)
  b$baseline <- NULL
  expect_null(c(a, b)$baseline)
})

test_that("default CSV round trip preserves channels, shots and metadata values", {
  s <- ls_spectrum(c(503, 501, 502), rbind(c(30, 10, 20), c(60, 20, 40)),
                   metadata = list(sample_id = "001", operator = "A\nB: # test",
                                   concentration = 3.2, approved = FALSE),
                   baseline = c(3, 1, 2))
  path <- withr::local_tempfile(fileext = ".csv")
  ls_write_csv(s, path)
  read <- ls_read_spectrum(path, verbose = FALSE)
  expect_equal(read$wavelength, s$wavelength)
  expect_equal(read$intensity, s$intensity)
  expect_equal(read$baseline, s$baseline)
  expect_equal(read$metadata[names(s$metadata)], s$metadata)
  expect_equal(read$metadata$source_file, path)
  expect_equal(length(readLines(path)), s$n_channels + 2L)
})

test_that("exported datasets import with matching sample labels", {
  specs <- lapply(c("002", "001"), function(id) {
    ls_spectrum(500:502, 1:3, list(sample_id = id))
  })
  ds <- ls_dataset(specs, data.frame(sample_id = c("002", "001"), group = c("x", "y")))
  dir <- withr::local_tempdir()
  ls_export_spectra(ds, dir)
  read <- ls_read_dir(dir, verbose = FALSE)
  expect_equal(read$sample_info$sample_id, c("001", "002"))
  expect_equal(read$sample_info$group, c("y", "x"))
})

test_that("all export destinations are checked before any file is written", {
  parent <- withr::local_tempdir()
  out <- file.path(parent, "export")
  for (id in c("../escaped", "sample_info", "SAMPLE_INFO", "a/b", "a\\b", "CON", ".hidden")) {
    ds <- ls_dataset(list(ls_spectrum(500:502, 1:3, list(sample_id = id))))
    expect_error(ls_export_spectra(ds, out), "portable filenames")
    expect_false(dir.exists(out))
  }
  ds <- ls_dataset(lapply(c("same", "SAME"), function(id) {
    ls_spectrum(500:502, 1:3, list(sample_id = id))
  }))
  expect_error(ls_export_spectra(ds, out), "portable filenames")
  expect_false(file.exists(file.path(parent, "escaped.csv")))
})

test_that("existing metadata and spectra are preserved when overwrite is false", {
  dir <- withr::local_tempdir()
  ds <- ls_dataset(list(ls_spectrum(500:502, 1:3, list(sample_id = "a"))))
  ls_export_spectra(ds, dir)
  paths <- list.files(dir, full.names = TRUE)
  before <- tools::md5sum(paths)
  changed <- ls_dataset(list(ls_spectrum(500:502, 9:11, list(sample_id = "a"))))
  changed$sample_info$note <- "new"
  expect_warning(ls_export_spectra(changed, dir), "whole dataset")
  expect_identical(tools::md5sum(paths), before)
})

test_that("ordinary publication failures restore the complete previous export", {
  dir <- withr::local_tempdir()
  ds <- ls_dataset(list(ls_spectrum(500:502, 1:3, list(sample_id = "a"))))
  ls_export_spectra(ds, dir)
  paths <- list.files(dir, full.names = TRUE)
  before <- tools::md5sum(paths)
  changed <- ls_dataset(list(ls_spectrum(500:502, 9:11, list(sample_id = "a"))))
  testthat::local_mocked_bindings(.move_export_file = function(from, to) {
    if (basename(from) == "sample_info.csv" && grepl("libscanR-", dirname(from))) {
      return(FALSE)
    }
    file.rename(from, to)
  })
  expect_error(ls_export_spectra(changed, dir, overwrite = TRUE), "restoring")
  expect_identical(tools::md5sum(paths), before)
  expect_equal(sort(list.files(dir, all.files = TRUE, no.. = TRUE)), sort(basename(paths)))
})

test_that("symbolic output targets are rejected without modifying their contents", {
  skip_on_os("windows")
  dir <- withr::local_tempdir()
  original <- file.path(dir, "original")
  writeLines("keep", original)
  link <- file.path(dir, "link.csv")
  expect_true(file.symlink(original, link))
  expect_error(ls_write_csv(ls_spectrum(500:502, 1:3), link), "symbolic link")
  expect_equal(readLines(original), "keep")
})

test_that("vendor and headerless imports retain the first channel", {
  path <- withr::local_tempfile(fileext = ".csv")
  writeLines(c("Applied Spectra J200", "wl,shot1,shot2", "200,1,2", "201,3,4", "202,5,6"), path)
  x <- ls_read_aurora(path, verbose = FALSE)
  expect_equal(x$wavelength, 200:202)
  expect_equal(x$intensity, rbind(c(1, 3, 5), c(2, 4, 6)))
  writeLines(c("# SciAps", "200,1", "201,2", "202,3"), path)
  expect_equal(ls_read_sciaps(path, verbose = FALSE)$wavelength, 200:202)
  writeLines(c("200,1", "201,2", "202,3"), path)
  expect_equal(ls_read_spectrum(path, verbose = FALSE)$wavelength, 200:202)
  writeLines(c("wavelength,intensity", "200,1", "201,bad", "202,3"), path)
  expect_error(ls_read_spectrum(path, verbose = FALSE), "no rows were discarded")
  expect_error(ls_read_aurora(path, verbose = FALSE), "no rows were discarded")
})

test_that("list names do not alter sample identity and processing survives CSV", {
  s <- ls_spectrum(500:510, c(1, 2, 3, 4, 8, 9, 8, 4, 3, 2, 1),
                   list(sample_id = "a", source_file = "original.csv"))
  ds <- ls_dataset(list(named_sample = s))
  expect_true(.validate_dataset(ds))
  transformed <- ls_smooth(ls_normalize(s, "max"), "moving_avg", window = 3)
  file <- withr::local_tempfile(fileext = ".csv")
  ls_write_csv(transformed, file)
  reread <- ls_read_spectrum(file, verbose = FALSE)
  expect_equal(reread$metadata$processing, transformed$metadata$processing)
  expect_equal(reread$metadata$source_history[[1]]$source_file, "original.csv")
  expect_equal(reread$intensity, transformed$intensity)
})

test_that("malformed rectangular input is rejected without guessing a lost channel", {
  file <- withr::local_tempfile(fileext = ".csv")
  writeLines(c("wavelength,intensity", "500,1,2", "501,2,3", "502,3,4"), file)
  expect_error(ls_read_spectrum(file, verbose = FALSE), "inconsistent column counts")
})
test_that("structural fields and metadata use exact names", {
  s <- ls_spectrum(1:4, 2:5, metadata = list(sample_id_unknown = "wrong"))
  d <- ls_dataset(list(s))
  expect_identical(d$sample_info$sample_id, "sample_1")
  invalid <- s
  names(invalid)[names(invalid) == "wavelength"] <- "wavelength_unknown"
  expect_error(ls_normalize(invalid), "Invalid.*structure")
  invalid <- d
  names(invalid)[names(invalid) == "intensity_matrix"] <- "intensity_matrix_unknown"
  expect_error(ls_normalize(invalid), "Invalid dataset structure")
  invalid <- d
  names(invalid$sample_info)[1] <- "sample_id_unknown"
  expect_error(ls_normalize(invalid), "alignment")
  s$metadata$processing_unknown <- list(list(operation = "not-performed"))
  processed <- ls_normalize(s)
  expect_length(processed$metadata$processing, 1L)
  expect_identical(processed$metadata$processing[[1]]$operation, "normalize")
  expect_identical(processed$metadata$processing_unknown, s$metadata$processing_unknown)
})
