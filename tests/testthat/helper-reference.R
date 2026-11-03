# Fictional parser/filter fixture; no rows are copied from an atomic database.
# Tests never consume an unrelated user reference. Restore caller configuration
# when the test run ends; individual configuration tests set their own files.
if (testthat::is_testing()) {
  withr::local_options(list(libscanR.element_db = NULL), .local_envir = testthat::teardown_env())
  withr::local_envvar(LIBSCANR_ELEMENT_DB = NA_character_, .local_envir = testthat::teardown_env())
}

synthetic_reference_file <- function(extension = "csv") {
  db <- data.frame(element = c("Ca", "Ca", "X", "Na"),
    ionization = c(1L, 2L, 1L, 1L), wavelength_nm = c(393.37, 410, 500, 589),
    aki = c(1, NA_real_, 2, .5), ei_ev = c(0, 0, 1, 0), ek_ev = c(3, 4, 5, 2),
    persistent = c(TRUE, FALSE, FALSE, TRUE), wavelength_medium = "vacuum",
    source = "Fictional software regression fixture; not NIST or experimental data")
  path <- tempfile(fileext = paste0(".", extension))
  if (extension == "csv") utils::write.csv(db, path, row.names = FALSE, na = "")
  else saveRDS(db, path)
  path
}
