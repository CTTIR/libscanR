#' Write a LIBS Spectrum to CSV
#'
#' Exports a `libs_spectrum` to a CSV file with a `wavelength_nm` column plus
#' one column per shot.
#'
#' @param x A `libs_spectrum` object.
#' @param path Character. Output file path.
#' @param include_metadata Logical. Prepend metadata as comment lines.
#'   Default `TRUE`. JSON comments preserve scalar values, arrays, nested lists,
#'   and the baseline. Named vectors become JSON objects (lists on import);
#'   R-specific classes and attributes are not preserved.
#'
#' @return Invisibly returns `path`.
#'
#' @examples
#' spec <- ls_simulate_spectrum(seed = 1)
#' tmp <- tempfile(fileext = ".csv")
#' ls_write_csv(spec, tmp)
#' unlink(tmp)
#'
#' @export
ls_write_csv <- function(x, path, include_metadata = TRUE) {
  .validate_spectrum(x)
  .check_flag(include_metadata, "include_metadata")
  .check_output_path(path)
  if (!dir.exists(dirname(path))) cli::cli_abort("Output directory does not exist.")
  staging <- tempfile(".libscanR-", tmpdir = dirname(path))
  dir.create(staging)
  on.exit(unlink(staging, recursive = TRUE), add = TRUE)
  staged <- file.path(staging, "spectrum.csv")
  .write_spectrum_csv(x, staged, include_metadata)
  .publish_files(staged, path)
  invisible(path)
}

.write_spectrum_csv <- function(x, path, include_metadata = TRUE) {
  df <- data.frame(wavelength_nm = x$wavelength)
  for (i in seq_len(x$n_shots)) {
    key <- if (x$n_shots == 1L) "intensity" else paste0("shot_", i)
    df[[key]] <- as.numeric(x$intensity[i, ])
  }
  # Encode before opening a file: unsupported metadata must not truncate output.
  header <- if (include_metadata) paste0("# libscanR-json-v1: ",
    jsonlite::toJSON(list(metadata = .json_metadata(x$metadata), baseline = x$baseline),
                     auto_unbox = TRUE, null = "null", digits = NA)) else character()
  con <- file(path, open = "wt", encoding = "UTF-8")
  on.exit(close(con), add = TRUE)
  if (length(header)) writeLines(header, con, useBytes = TRUE)
  utils::write.csv(df, con, row.names = FALSE)
}

#' Export a LIBS Dataset to a Directory
#'
#' Writes each spectrum in a dataset as a separate CSV file, plus a
#' `sample_info.csv` metadata table. IDs must be unique portable filenames.
#' Existing output is left intact if `overwrite = FALSE`; if any target exists,
#' the whole export is skipped. All files are staged before replacement, with
#' rollback on ordinary write failures. Concurrent writers and power-loss
#' recovery are not supported.
#'
#' @param dataset A `libs_dataset` object.
#' @param dir Character. Output directory (created if missing).
#' @param overwrite Logical. Overwrite existing files. Default `FALSE`.
#'
#' @return Invisibly returns `dir`.
#'
#' @examples
#' ds <- ls_example_data("tissue")[1:3]
#' tmp <- tempfile()
#' ls_export_spectra(ds, tmp)
#' list.files(tmp)
#' unlink(tmp, recursive = TRUE)
#'
#' @export
ls_export_spectra <- function(dataset, dir, overwrite = FALSE) {
  .validate_dataset(dataset)
  .check_flag(overwrite, "overwrite")
  .check_output_path(dir, directory = TRUE)
  ids <- dataset$sample_info$sample_id
  bad <- grepl('[[:cntrl:]/:*?"<>|]', ids) | grepl("\\", ids, fixed = TRUE) |
    grepl("^[.]|[. ]$", ids) |
    grepl("^(sample_info|con|prn|aux|nul|com[1-9]|lpt[1-9])$",
          ids, ignore.case = TRUE)
  if (any(bad) || anyDuplicated(tolower(ids))) {
    cli::cli_abort("Sample IDs must be distinct portable filenames, without paths or reserved names.")
  }
  names <- c(paste0(ids, ".csv"), "sample_info.csv")
  paths <- file.path(dir, names)
  invisible(lapply(paths, .check_output_path))
  existing <- if (dir.exists(dir)) list.files(dir, all.files = TRUE) else character()
  aliases <- existing[tolower(existing) %in% tolower(names) & !existing %in% names]
  if (length(aliases)) cli::cli_abort("Output filenames collide by letter case with existing files.")
  if (!overwrite && any(file.exists(paths))) {
    cli::cli_warn("Export files already exist; skipping the whole dataset (set {.arg overwrite = TRUE}).")
    return(invisible(dir))
  }
  if (!dir.exists(dir) && !dir.create(dir, recursive = TRUE)) {
    cli::cli_abort("Cannot create export directory.")
  }
  staging <- tempfile(".libscanR-", tmpdir = dir)
  dir.create(staging)
  on.exit(unlink(staging, recursive = TRUE), add = TRUE)
  staged <- file.path(staging, names)
  for (i in seq_along(dataset$spectra)) {
    .write_spectrum_csv(dataset$spectra[[i]], staged[i])
  }
  utils::write.csv(dataset$sample_info, tail(staged, 1L), row.names = FALSE)
  .publish_files(staged, paths)
  invisible(dir)
}

.check_output_path <- function(path, directory = FALSE) {
  if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(path)) {
    cli::cli_abort("Output path must be a single non-empty string.")
  }
  # Resolve ordinary parent aliases such as macOS /var -> /private/var, but
  # never follow a link occupying a target file or the export directory itself.
  link <- Sys.readlink(path.expand(path))
  if (!is.na(link) && nzchar(link)) {
    cli::cli_abort("The output target must not be a symbolic link.")
  }
  if (!directory && dir.exists(path)) cli::cli_abort("Output file is a directory.")
  if (!directory && file.exists(path) && !file_test("-f", path)) {
    cli::cli_abort("Existing output must be a regular file.")
  }
  if (directory && file.exists(path) && !dir.exists(path)) {
    cli::cli_abort("Output directory is an existing file.")
  }
  invisible(TRUE)
}

.move_export_file <- function(from, to) file.rename(from, to)

.json_metadata <- function(x) {
  if (is.list(x)) return(lapply(x, .json_metadata))
  if (is.atomic(x) && !is.null(names(x))) return(lapply(as.list(x), .json_metadata))
  x
}

.publish_files <- function(staged, paths) {
  # Stage every output first. Roll back ordinary filesystem failures as a set.
  # This is not a transaction across a power loss or concurrent writers.
  backup <- tempfile(".libscanR-backup-", tmpdir = dirname(paths[1]))
  if (!dir.create(backup)) cli::cli_abort("Cannot create export backup directory.")
  old <- file.path(backup, as.character(seq_along(paths)))
  saved <- written <- rep(FALSE, length(paths))
  success <- FALSE
  on.exit({
    recovered <- TRUE
    if (!success) {
      for (i in rev(seq_along(paths))) {
        if (written[i]) unlink(paths[i])
        if (saved[i] && !file.rename(old[i], paths[i])) recovered <- FALSE
      }
    }
    if (recovered) unlink(backup, recursive = TRUE) else {
      warning("Export recovery needs attention; original files are in: ", backup)
    }
  }, add = TRUE)
  for (i in seq_along(paths)) {
    .check_output_path(paths[i])
    if (file.exists(paths[i])) {
      if (!.move_export_file(paths[i], old[i])) cli::cli_abort("Cannot preserve existing export file.")
      saved[i] <- TRUE
    }
    if (!.move_export_file(staged[i], paths[i])) cli::cli_abort("Cannot publish export file; restoring previous output.")
    written[i] <- TRUE
  }
  success <- TRUE
  invisible(paths)
}
