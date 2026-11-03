test_that("ls_find_peaks detects simulated peaks", {
  s <- ls_simulate_spectrum(line_data = ls_demo_peaks(), elements = c(Ca = 5000, Na = 1000),
                            seed = 1, n_channels = 512)
  pk <- ls_find_peaks(s, snr_threshold = 3)
  expect_s3_class(pk, "tbl_df")
  expect_gt(nrow(pk), 0)
  expect_true(all(c("wavelength_nm", "intensity", "snr",
                    "prominence", "fwhm_nm", "area") %in% names(pk)))
})

test_that("ls_identify_peaks matches Ca 393.37", {
  withr::local_options(list(libscanR.element_db = synthetic_reference_file()))
  s <- ls_simulate_spectrum(line_data = ls_demo_peaks(), elements = c(Ca = 10000),
                            seed = 1, n_channels = 1024)
  pk <- ls_find_peaks(s, snr_threshold = 2)
  id <- ls_identify_peaks(pk, elements = "Ca", tolerance_nm = 0.5)
  expect_true("Ca" %in% id$element)
})

test_that("ls_peak_area integrates to positive value", {
  s <- ls_simulate_spectrum(line_data = ls_demo_peaks(), elements = c(Ca = 10000),
                            seed = 1, n_channels = 512)
  s <- ls_baseline(s, method = "snip", iterations = 30)
  area <- ls_peak_area(s, 393.37, window_nm = 2)
  expect_gte(area, 0)
})

test_that("ls_element_db returns a tibble", {
  withr::local_options(list(libscanR.element_db = synthetic_reference_file()))
  db <- ls_element_db()
  expect_s3_class(db, "tbl_df")
  expect_true(all(c("element", "ionization", "wavelength_nm",
                    "aki", "ei_ev", "ek_ev", "persistent") %in% names(db)))
  expect_equal(nrow(db), 4L)
})

test_that("ls_element_db filters correctly", {
  withr::local_options(list(libscanR.element_db = synthetic_reference_file()))
  db <- ls_element_db(elements = "Ca", persistent_only = TRUE)
  expect_true(all(db$element == "Ca"))
  expect_true(all(db$persistent))
})
