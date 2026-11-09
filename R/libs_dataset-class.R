#' Create a LIBS Dataset
#'
#' Constructs a `libs_dataset`: a collection of [ls_spectrum()] objects
#' sharing a common wavelength axis, plus a sample-info table.
#'
#' @param spectra List of `libs_spectrum` objects. All must share the same
#'   wavelength axis (exact channel values). Resample deliberately before
#'   combining measurements on different axes; no channels are relabeled.
#' @param sample_info Optional data.frame or tibble with one row per spectrum.
#'   Must contain column `sample_id` matching `metadata$sample_id` in each
#'   spectrum. Additional columns (e.g. `material`, `group`, `concentration`,
#'   `x_pos`, `y_pos`) are optional. If NULL, built from spectrum metadata.
#'
#' @return A `libs_dataset` S3 object.
#'
#' @examples
#' specs <- lapply(1:3, function(i) {
#'   ls_simulate_spectrum(line_data = ls_demo_peaks(), elements = c(Ca = 1000 * i, Na = 500), seed = i)
#' })
#' specs <- Map(function(s, id) {
#'   s$metadata$sample_id <- paste0("s", id)
#'   s
#' }, specs, seq_along(specs))
#' ds <- ls_dataset(specs)
#' print(ds)
#'
#' @export
ls_dataset <- function(spectra, sample_info = NULL) {
  if (!is.list(spectra) || length(spectra) == 0) {
    cli::cli_abort("{.arg spectra} must be a non-empty list.")
  }
  ok <- vapply(spectra, inherits, logical(1), "libs_spectrum")
  if (!all(ok)) {
    cli::cli_abort("All elements of {.arg spectra} must be {.cls libs_spectrum}.")
  }
  invisible(lapply(spectra, .validate_spectrum))

  wl <- spectra[[1]]$wavelength
  n_ch <- length(wl)
  for (i in seq_along(spectra)[-1]) {
    wl_i <- spectra[[i]]$wavelength
    if (length(wl_i) != n_ch) {
      cli::cli_abort(c(
        "Spectra have inconsistent channel counts.",
        "i" = "Spectrum 1: {n_ch} channels; spectrum {i}: {length(wl_i)} channels."
      ))
    }
    if (!.same_axis(wl_i, wl)) {
      cli::cli_abort("Spectra wavelength axes differ; align them explicitly before combining.")
    }
  }

  sample_ids <- unname(vapply(spectra, function(s) {
    .sample_id(.meta_get(s$metadata, "sample_id", NULL))
  }, character(1)))

  if (anyDuplicated(sample_ids[!is.na(sample_ids)])) {
    cli::cli_abort("Spectrum sample_ids must be unique.")
  }
  for (i in which(is.na(sample_ids))) {
    candidate <- paste0("sample_", i)
    while (candidate %in% sample_ids) candidate <- paste0(candidate, "_")
    sample_ids[i] <- candidate
  }
  for (i in seq_along(spectra)) {
    spectra[[i]]$metadata$sample_id <- sample_ids[i]
  }

  if (is.null(sample_info)) {
    materials <- vapply(spectra, function(s) {
      as.character(.meta_get(s$metadata, "material", NA_character_))
    }, character(1))
    sample_info <- tibble::tibble(
      sample_id = sample_ids,
      material = materials
    )
  } else {
    if (!is.data.frame(sample_info)) {
      cli::cli_abort("{.arg sample_info} must be a data.frame or tibble.")
    }
    sample_info <- tibble::as_tibble(sample_info)
    if (!"sample_id" %in% names(sample_info)) {
      cli::cli_abort("{.arg sample_info} must contain column {.val sample_id}.")
    }
    if (nrow(sample_info) != length(spectra)) {
      cli::cli_abort(c(
        "{.arg sample_info} rows must match {.arg spectra} length.",
        "i" = "{nrow(sample_info)} rows vs {length(spectra)} spectra."
      ))
    }
    sample_info$sample_id <- vapply(as.list(sample_info$sample_id),
                                    .sample_id, character(1),
                                    allow_missing = FALSE)
    if (anyDuplicated(sample_info$sample_id) ||
        !setequal(sample_info$sample_id, sample_ids)) {
      cli::cli_abort("sample_info$sample_id must match every spectrum sample_id exactly once.")
    }
    sample_info <- sample_info[match(sample_ids, sample_info$sample_id), ]
  }

  structure(
    list(
      spectra = spectra,
      sample_info = sample_info,
      wavelength = wl,
      n_spectra = length(spectra),
      n_channels = n_ch,
      intensity_matrix = .build_intensity_matrix(spectra),
      range_nm = range(wl)
    ),
    class = "libs_dataset"
  )
}

#' Test whether an object is a libs_dataset
#'
#' @param x Object to test.
#' @return Logical scalar.
#' @examples
#' ds <- ls_example_data("calibration")
#' is_libs_dataset(ds)
#' is_libs_dataset(list())
#' @export
is_libs_dataset <- function(x) {
  inherits(x, "libs_dataset")
}
