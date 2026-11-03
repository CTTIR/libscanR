app_modules <- function() {
  for (pkg in c("shiny", "bslib", "plotly", "DT")) skip_if_not_installed(pkg)
  env <- new.env(parent = globalenv())
  path <- system.file("shiny", "libscanR", package = "libscanR")
  if (!nzchar(path)) path <- test_path("..", "..", "inst", "shiny", "libscanR")
  for (file in list.files(file.path(path, "modules"), "[.]R$", full.names = TRUE)) {
    sys.source(file, envir = env)
  }
  env
}

app_fixture <- function() {
  wl <- seq(390, 600, length.out = 64)
  specs <- lapply(seq_len(12), function(i) ls_spectrum(wl,
    rbind(10 + i * sin(wl / 10) + i^2 * wl / 100,
          11 + i * sin(wl / 10) + i^2 * wl / 100),
    metadata = list(sample_id = paste0("s", i), provenance = list(kind = "synthetic"))))
  ls_dataset(specs, data.frame(sample_id = paste0("s", seq_len(12)),
    concentration = seq_len(12), tissue = rep(c("A", "B"), each = 6)))
}

app_state <- function(data = NULL) shiny::reactiveValues(raw_data = data,
  processed_data = NULL, import_error = NULL, peaks = NULL, calibrations = list(),
  pca_result = NULL, plsda_result = NULL, cluster_result = NULL)

test_that("uploads retain original format, identity and all shots", {
  app <- app_modules()
  staging <- tempfile(); dir.create(staging)
  withr::defer(unlink(staging, recursive = TRUE))
  path <- file.path(staging, "0")
  writeLines(c("wavelength\tshot1\tshot2", "400\t1\t3", "401\t2\t4"), path)
  files <- data.frame(name = "actual.tsv", datapath = path)
  spec <- app$.ls_app_upload(files, "auto")
  expect_equal(spec$wavelength, c(400, 401))
  expect_equal(unname(spec$intensity), rbind(c(1, 2), c(3, 4)))
  expect_identical(spec$metadata$sample_id, "actual")
  expect_identical(spec$metadata$source_file, "actual.tsv")
  expect_identical(spec$metadata$source_location, "browser upload")
  expect_error(app$.ls_app_upload(transform(files, name = "../actual.tsv"), "auto"), "without paths")
  expect_error(app$.ls_app_upload(rbind(files, files), "auto"), "distinct")
})

test_that("failed batch admission preserves the previous valid state", {
  app <- app_modules(); initial <- app_fixture(); rv <- app_state(initial)
  staging <- tempfile(); dir.create(staging)
  withr::defer(unlink(staging, recursive = TRUE))
  ls_write_csv(initial$spectra[[1]], file.path(staging, "0"))
  writeLines("invalid spectrum", file.path(staging, "1"))
  files <- data.frame(name = c("valid.csv", "broken.tsv"), datapath = file.path(staging, c("0", "1")))
  shiny::testServer(app$mod_import_server, args = list(rv = rv), {
    session$setInputs(format = "auto", file = files)
    expect_identical(rv$raw_data, initial)
    expect_match(rv$import_error, "broken.tsv")
    expect_match(output$status$html, "previously loaded data are retained")
    session$setInputs(file = files[1, , drop = FALSE])
    expect_s3_class(rv$raw_data, "libs_spectrum")
    expect_identical(rv$raw_data$metadata$sample_id, "s1")
    expect_null(rv$import_error)
  })
})

test_that("admitting identical data still clears every derived result", {
  app <- app_modules(); initial <- app_fixture(); rv <- app_state(initial)
  shiny::isolate({
    rv$processed_data <- initial; rv$peaks <- data.frame(x = 1)
    rv$calibrations <- list(Ca = 1); rv$pca_result <- 1
    rv$plsda_result <- 1; rv$cluster_result <- 1
    app$.ls_app_admit(rv, initial)
    expect_identical(rv$raw_data, initial)
    expect_null(rv$processed_data); expect_null(rv$peaks)
    expect_length(rv$calibrations, 0)
    expect_null(rv$pca_result); expect_null(rv$plsda_result)
    expect_null(rv$cluster_result)
  })
})

test_that("preprocessing failure retains the last applied data and reset invalidates results", {
  app <- app_modules(); initial <- app_fixture(); rv <- app_state(initial)
  shiny::testServer(app$mod_preprocess_server, args = list(rv = rv), {
    session$setInputs(baseline_method = "none", norm_method = "max",
      smooth_method = "none", crop_min = 0, crop_max = 0, apply = 1)
    expect_equal(rv$processed_data$spectra[[1]]$intensity,
                 ls_normalize(initial, "max")$spectra[[1]]$intensity)
    prior <- rv$processed_data
    session$setInputs(crop_min = 900, crop_max = 800, apply = 2)
    expect_identical(rv$processed_data, prior)
    expect_match(status(), "Failed:.*previous data are retained")
    rv$peaks <- data.frame(x = 1); rv$calibrations <- list(Ca = 1)
    session$setInputs(reset = 1)
    expect_null(rv$processed_data); expect_null(rv$peaks)
    expect_length(rv$calibrations, 0)
    expect_match(status(), "raw data")
  })
})

test_that("calibration controls and errors cannot retain an obsolete fit", {
  app <- app_modules(); rv <- app_state(app_fixture())
  shiny::testServer(app$mod_calibration_server, args = list(rv = rv), {
    session$setInputs(element = "Ca", line_nm = 393.37, method = "univariate",
      internal_std = 589, window = 10, conc_col = "concentration", build = 1)
    expect_s3_class(rv$calibrations$Ca, "libs_calibration")
    session$setInputs(window = 12)
    expect_null(rv$calibrations$Ca)
    session$setInputs(conc_col = "absent", build = 2)
    expect_null(rv$calibrations$Ca)
    expect_match(status(), "Failed:.*absent")
  })
})

test_that("chemometrics controls invalidate only the affected fit and failures remain visible", {
  app <- app_modules(); rv <- app_state(app_fixture())
  shiny::testServer(app$mod_chemometrics_server, args = list(rv = rv), {
    session$setInputs(pca_n = 2, pca_color = "tissue", cluster_method = "hclust",
      cluster_k = 2, run_pca = 1, run_cluster = 1)
    expect_s3_class(rv$pca_result, "libs_pca")
    expect_s3_class(rv$cluster_result, "libs_clusters")
    prior <- rv$pca_result
    session$setInputs(pca_color = "absent")
    expect_identical(rv$pca_result, prior)
    session$setInputs(pca_n = 3)
    expect_null(rv$pca_result)
    expect_s3_class(rv$cluster_result, "libs_clusters")
    session$setInputs(cluster_k = 99, run_cluster = 2)
    expect_null(rv$cluster_result)
    expect_match(cluster_status(), "Failed:")
    rv$raw_data <- rv$raw_data$spectra[[1]]
    session$flushReact()
    session$setInputs(run_pca = 2)
    expect_null(rv$pca_result)
    expect_match(pca_status(), "dataset with multiple spectra")
  })
})

test_that("complete archives retain shots, source metadata and sample information", {
  app <- app_modules()
  skip_if(Sys.which(Sys.getenv("R_ZIPCMD", "zip")) == "",
    "configured system zip command unavailable")
  staging <- tempfile(); dir.create(staging)
  withr::defer(unlink(staging, recursive = TRUE))
  original <- app_fixture()[1:2]
  archive <- file.path(staging, "spectra.zip")
  app$.ls_app_archive(original, archive)
  members <- utils::unzip(archive, list = TRUE)$Name
  expect_setequal(members, c("s1.csv", "s2.csv", "sample_info.csv"))
  utils::unzip(archive, exdir = staging)
  readback <- ls_read_spectrum(file.path(staging, "s1.csv"), verbose = FALSE)
  expect_equal(unname(readback$intensity), unname(original$spectra[[1]]$intensity))
  expect_equal(readback$metadata$provenance, list(kind = "synthetic"))
  expect_equal(read.csv(file.path(staging, "sample_info.csv")), as.data.frame(original$sample_info))
  means <- app$.ls_app_mean_table(original)
  expect_equal(means$s1, colMeans(original$spectra[[1]]$intensity))
  original$spectra[[1]]$metadata$sample_id <- "wavelength_nm"
  original$sample_info$sample_id[1] <- "wavelength_nm"
  expect_error(app$.ls_app_mean_table(original), "conflicts.*complete ZIP")
})

test_that("scientific warnings remain visible and do not become silent successes", {
  app <- app_modules(); seen <- character()
  with_mocked_bindings({
    expect_warning(result <- app$.ls_app_attempt({warning("Synthetic QC warning"); 42}), "Synthetic QC warning")
    expect_true(result$ok); expect_identical(result$value, 42)
  }, showNotification = function(ui, ...) { seen <<- c(seen, ui) }, .package = "shiny")
  expect_identical(seen, "Synthetic QC warning")
})

test_that("the served app invalidates derived data centrally and isolates sessions", {
  app <- app_modules()
  path <- system.file("shiny", "libscanR", package = "libscanR")
  sys.source(file.path(path, "app.R"), envir = app)
  fixture_data <- app_fixture()
  session_one <- shiny::MockShinySession$new()
  session_one$options <- list(libscanR.data = fixture_data)
  session_two <- shiny::MockShinySession$new()
  session_two$options <- list(libscanR.data = fixture_data)
  shiny::testServer(app$server, session = session_one, {
    session$flushReact()
    rv$processed_data <- fixture_data
    session$flushReact()
    rv$peaks <- data.frame(x = 1); rv$calibrations <- list(Ca = 1)
    rv$pca_result <- 1; rv$plsda_result <- 1; rv$cluster_result <- 1
    rv$raw_data <- fixture_data[1:2]
    session$flushReact()
    expect_null(rv$processed_data); expect_null(rv$peaks)
    expect_length(rv$calibrations, 0)
    expect_null(rv$pca_result); expect_null(rv$plsda_result)
    expect_null(rv$cluster_result)
    rv$peaks <- data.frame(x = 2)
    rv$processed_data <- ls_normalize(rv$raw_data, "max")
    session$flushReact()
    expect_null(rv$peaks)
  })
  shiny::testServer(app$server, session = session_two, {
    session$flushReact()
    expect_identical(rv$raw_data, fixture_data)
    expect_null(rv$processed_data); expect_null(rv$peaks)
    expect_length(rv$calibrations, 0)
  })
})

test_that("peak markers and exports use the detected table and stale controls clear it", {
  app <- app_modules()
  wl <- seq(390, 410, length.out = 201)
  y <- 2 + sin(wl * 2) / 50 + 100 * exp(-(wl - 393)^2 / 0.08) +
    10 * exp(-(wl - 403)^2 / 0.08)
  rv <- app_state(ls_spectrum(wl, y, list(sample_id = "peak-fixture")))
  shiny::testServer(app$mod_peaks_server, args = list(rv = rv), {
    session$setInputs(snr = 1, prom = 0.2, dist = 0.5,
                     elements = character(), detect = 1)
    expect_gt(nrow(rv$peaks), 0)
    expect_true(all(rv$peaks$sample_id == "peak-fixture"))
    widget <- jsonlite::fromJSON(output$plot, simplifyVector = FALSE)
    markers <- Filter(function(trace) identical(trace$mode, "markers"), widget$x$data)
    expect_length(markers, 1)
    expect_equal(as.numeric(unlist(markers[[1]]$x)), rv$peaks$wavelength_nm)
    expect_equal(as.numeric(unlist(markers[[1]]$y)), rv$peaks$intensity)
    session$setInputs(prom = 0.001)
    expect_null(rv$peaks)
    expect_match(status(), "Ready")
  })
})

test_that("download rejection explains how to create current results", {
  app <- app_modules(); rv <- app_state(app_fixture()); seen <- character()
  with_mocked_bindings({
    shiny::testServer(app$mod_export_server, args = list(rv = rv), {
      expect_error(output$dl_peaks, class = "shiny.silent.error")
      expect_true(any(grepl("Detect peaks for the current data", seen)))
      expect_error(output$dl_calibration, class = "shiny.silent.error")
      expect_true(any(grepl("Build a calibration for the current data", seen)))
      expect_match(output$summary$html, "Detect peaks before downloading")
    })
  }, showNotification = function(ui, ...) { seen <<- c(seen, ui) }, .package = "shiny")
})

test_that("single-spectrum preload labels use only the exact sample ID field", {
  app <- app_modules()
  wl <- seq(390, 410, length.out = 201)
  spec <- ls_spectrum(wl, 2 + 100 * exp(-(wl - 393)^2 / 0.08),
    metadata = list(sample_id_unknown = "not-the-sample-id"))
  path <- system.file("shiny", "libscanR", package = "libscanR")
  sys.source(file.path(path, "app.R"), envir = app)
  mock_session <- shiny::MockShinySession$new()
  mock_session$options <- list(libscanR.data = spec)
  shiny::testServer(app$server, session = mock_session, {
    session$setInputs(`peaks-snr` = 1, `peaks-prom` = 0.01,
      `peaks-dist` = 0.5, `peaks-elements` = character(), `peaks-detect` = 1)
    expect_gt(nrow(rv$peaks), 0)
    expect_true(all(rv$peaks$sample_id == "spectrum"))
    expect_identical(rv$raw_data$metadata[["sample_id_unknown"]],
      "not-the-sample-id")
  })
})

test_that("reloading identical input cannot leave a Complete label without results", {
  app <- app_modules(); fixture_data <- app_fixture(); rv <- app_state(fixture_data)
  shiny::testServer(app$mod_chemometrics_server, args = list(rv = rv), {
    session$setInputs(pca_n = 2, pca_color = "tissue", run_pca = 1)
    expect_match(output$pca_state$html, "Complete")
    app$.ls_app_admit(rv, fixture_data)
    session$flushReact()
    expect_null(rv$pca_result)
    expect_match(output$pca_state$html, "Ready")
  })
})

test_that("calibration exports distinguish unavailable limits from training error", {
  app <- app_modules(); rv <- app_state(app_fixture())
  shiny::isolate(rv$calibrations <- list(Ca = list(element = "Ca",
    wavelength_nm = 393.37, method = "pls", r_squared = 0.9,
    lod = NA_real_, loq = NA_real_, unit = "ppm", n_standards = 12,
    lod_basis = "unavailable", training_rmse = 0.25)))
  shiny::testServer(app$mod_export_server, args = list(rv = rv), {
    exported <- read.csv(output$dl_calibration)
    expect_true(is.na(exported$lod) && is.na(exported$loq))
    expect_identical(exported$lod_basis, "unavailable")
    expect_equal(exported$training_rmse, 0.25)
  })
})

test_that("calibration figures are visible and distinguish unavailable PLS limits", {
  skip_if_not_installed("pls")
  app <- app_modules(); rv <- app_state(app_fixture())
  shiny::testServer(app$mod_calibration_server, args = list(rv = rv), {
    session$setInputs(element = "Ca", line_nm = 393.37, method = "pls",
      internal_std = 589, window = 1, conc_col = "concentration", build = 1)
    expect_match(output$stats, "Element: Ca")
    expect_match(output$stats, "Standards: 12")
    expect_match(output$stats, "LOD (ppm): Unavailable", fixed = TRUE)
    expect_match(output$stats, "LOQ (ppm): Unavailable", fixed = TRUE)
    expect_match(output$stats, "Training RMSE (ppm):", fixed = TRUE)
    expect_false(grepl("Training RMSE (ppm): Unavailable", output$stats, fixed = TRUE))
    session$setInputs(line_nm = 0)
    expect_null(rv$calibrations$Ca)
    expect_error(output$stats, class = "shiny.silent.error")
  })
})

test_that("peak detection and raw plots remain usable without an atomic reference", {
  app <- app_modules()
  withr::local_options(libscanR.element_db = NULL)
  withr::local_envvar(LIBSCANR_ELEMENT_DB = NA_character_)
  ui <- as.character(app$mod_peaks_ui("test"))
  expect_false(grepl('<option value="Ca" selected', ui, fixed = TRUE))
  wl <- seq(390, 410, length.out = 201)
  spec <- ls_spectrum(wl, 2 + 100 * exp(-(wl - 393)^2 / 0.08),
    metadata = list(sample_id = "reference-free"))
  rv <- app_state(spec)
  shiny::testServer(app$mod_peaks_server, args = list(rv = rv), {
    session$setInputs(snr = 1, prom = 0.01, dist = 0.5,
                     elements = character(), detect = 1)
    expect_gt(nrow(rv$peaks), 0)
    raw <- rv$peaks
    expect_match(output$plot, "plotly")
    session$setInputs(elements = "Ca", detect = 2)
    expect_equal(rv$peaks, raw)
    expect_match(status(), "Annotation unavailable")
    expect_match(output$reference_state$html, "libscanR.element_db")
    expect_match(output$plot, "plotly")
    expect_identical(rv$raw_data, spec)
    session$setInputs(elements = character(), detect = 3)
    expect_match(status(), "Complete")
    expect_null(output$reference_state)
  })
})

test_that("fictional teaching provenance is visible after loading and fitting", {
  app <- app_modules(); ds <- app_fixture()
  for (i in seq_along(ds$spectra)) {
    ds$spectra[[i]]$metadata$line_source <- list(kind = "explicit_synthetic_peaks")
  }
  rv <- app_state(ds)
  shiny::testServer(app$mod_import_server, args = list(rv = rv), {
    expect_match(output$status$html, "Fictional teaching")
    expect_match(output$status$html, "not.*experimental measurements")
  })
  shiny::testServer(app$mod_calibration_server, args = list(rv = rv), {
    session$setInputs(element = "Ca", line_nm = 393.37, method = "univariate",
      internal_std = 589, window = 10, conc_col = "concentration", build = 1)
    expect_s3_class(rv$calibrations$Ca, "libs_calibration")
    expect_match(output$state$html, "Fictional teaching")
    expect_match(output$stats, "Fictional teaching")
  })
  shiny::testServer(app$mod_export_server, args = list(rv = rv), {
    rv$peaks <- data.frame(wavelength_nm = 393, intensity = 10)
    expect_identical(read.csv(output$dl_peaks)$data_origin, "explicit_synthetic_peaks")
    expect_identical(read.csv(output$dl_calibration)$data_origin, "explicit_synthetic_peaks")
    expect_match(output$summary$html, "Fictional teaching")
  })
  expect_null(app$.ls_app_teaching_note(app_fixture()))
  alias <- ds$spectra[[1]]
  alias$metadata$line_source <- NULL
  alias$metadata$line_source_other <- list(kind = "explicit_synthetic_peaks")
  expect_null(app$.ls_app_teaching_note(alias))
})


test_that("teaching export provenance follows the actual source spectra", {
  app <- app_modules(); mixed <- app_fixture()
  mixed$spectra[[2]]$metadata$line_source <- list(kind = "explicit_synthetic_peaks")
  expect_identical(app$.ls_app_teaching_origin(mixed), "includes_explicit_synthetic_peaks")
  expect_null(app$.ls_app_teaching_origin(mixed$spectra[[1]]))
  rv <- app_state(mixed)
  shiny::isolate({
    rv$peaks <- data.frame(wavelength_nm = 393, intensity = 10)
    rv$calibrations <- list(Ca = ls_calibrate(mixed, "Ca", 393.37,
      mixed$sample_info$concentration, window_nm = 10, verbose = FALSE))
  })
  shiny::testServer(app$mod_export_server, args = list(rv = rv), {
    expect_false("data_origin" %in% names(read.csv(output$dl_peaks)))
    expect_identical(read.csv(output$dl_calibration)$data_origin,
      "includes_explicit_synthetic_peaks")
  })
})
