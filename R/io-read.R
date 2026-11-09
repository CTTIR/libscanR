#' Read a LIBS Spectrum from File
#'
#' Reads a single spectrum file. Supports CSV, TSV, and TXT formats where
#' columns represent wavelength and intensity.
#'
#' @param path Character. Path to spectrum file.
#' @param format Character. One of `"auto"` (detect from extension), `"csv"`,
#'   `"tsv"`, `"txt"`. Default `"auto"`.
#' @param wavelength_col Column index or name for wavelength values. Default 1.
#' @param intensity_col Column index/indices or name(s) for intensity values.
#'   Multiple columns are interpreted as multiple shots. Default 2.
#' @param skip Integer. Header lines to skip before the data table. Default 0.
#' @param metadata Named list of additional metadata. Default `list()`.
#' @param verbose Logical. Emit import messages. Default `TRUE`.
#'
#' @return A `libs_spectrum` object.
#'
#' @examples
#' tmp <- tempfile(fileext = ".csv")
#' wl <- seq(200, 900, length.out = 100)
#' int <- exp(-((wl - 393)^2) / 2)
#' utils::write.csv(data.frame(wavelength = wl, intensity = int),
#'                  tmp, row.names = FALSE)
#' spec <- ls_read_spectrum(tmp, verbose = FALSE)
#' unlink(tmp)
#'
#' @export
ls_read_spectrum <- function(path, format = "auto", wavelength_col = 1,
                             intensity_col = 2, skip = 0,
                             metadata = list(), verbose = TRUE) {
  .check_input_file(path)
  .check_number(skip, "skip", min = 0, integer = TRUE)
  .check_flag(verbose, "verbose")
  .check_metadata(metadata)
  format <- match.arg(format, c("auto", "csv", "tsv", "txt"))
  if (format == "auto") {
    ext <- tolower(tools::file_ext(path))
    format <- switch(ext, csv = "csv", tsv = "tsv", txt = "txt", "csv")
  }
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  if (skip >= length(lines)) cli::cli_abort("No data after skipped lines.")
  lines <- lines[seq.int(skip + 1L, length(lines))]
  payload <- .read_csv_metadata(lines)
  delim <- switch(format, csv = ",", tsv = "\t", txt = "")
  df <- .read_spectral_table(lines, delim = delim)
  wl <- .numeric_column(.pick_col(df, wavelength_col), "wavelength")
  int_df <- .pick_cols(df, intensity_col)
  intensity <- t(vapply(int_df, .numeric_column, numeric(nrow(df)),
                         name = "intensity"))
  dimnames(intensity) <- NULL
  meta <- utils::modifyList(list(
    sample_id = tools::file_path_sans_ext(basename(path))
  ), payload$metadata)
  meta <- utils::modifyList(meta, metadata)
  if (!is.null(.meta_get(meta, "source_file", NULL))) {
    meta$source_history <- c(.meta_get(meta, "source_history", list()),
                             list(list(source_file = meta[["source_file"]],
                                       import_time = .meta_get(meta, "import_time", NULL))))
  }
  meta$source_file <- path
  meta$import_time <- base::format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  spec <- ls_spectrum(wavelength = wl, intensity = intensity,
                      metadata = meta, baseline = payload[["baseline"]])

  if (verbose) {
    cli::cli_inform(c(
      "v" = "Read {.path {basename(path)}}: {spec$n_channels} channels, {spec$n_shots} shot(s)."
    ))
  }
  spec
}

#' Read All Spectra from a Directory
#'
#' Batch-imports spectrum files from a directory into a `libs_dataset`.
#'
#' @param dir Character. Directory path.
#' @param pattern Character. File pattern (regex). Default `"\\.(csv|tsv|txt)$"`.
#' @param recursive Logical. Recurse into subdirectories. Default `FALSE`.
#' @param sample_info data.frame/tibble. Optional sample metadata table.
#'   Must have a `sample_id` column matching all of the
#'   filenames without extension. Default `NULL`.
#' @param ... Additional arguments passed to [ls_read_spectrum()].
#'
#' @return A `libs_dataset` object.
#'
#' @examples
#' dir <- tempfile()
#' dir.create(dir)
#' for (i in 1:3) {
#'   wl <- seq(200, 900, length.out = 100)
#'   int <- exp(-((wl - 393)^2) / 2) + stats::rnorm(100, 0, 0.01)
#'   utils::write.csv(data.frame(w = wl, i = int),
#'                    file.path(dir, paste0("s", i, ".csv")),
#'                    row.names = FALSE)
#' }
#' ds <- ls_read_dir(dir, verbose = FALSE)
#' unlink(dir, recursive = TRUE)
#'
#' @export
ls_read_dir <- function(dir, pattern = "\\.(csv|tsv|txt)$",
                        recursive = FALSE, sample_info = NULL, ...) {
  if (!dir.exists(dir)) {
    cli::cli_abort("Directory not found: {.path {dir}}")
  }
  files <- list.files(dir, pattern = pattern, full.names = TRUE,
                      recursive = recursive)
  if (length(files) == 0) {
    cli::cli_abort("No files matching {.val {pattern}} in {.path {dir}}")
  }

  info_file <- file.path(dir, "sample_info.csv")
  files <- files[basename(files) != "sample_info.csv"]
  if (!length(files)) cli::cli_abort("No spectrum files remain after excluding sample_info.csv.")
  if (is.null(sample_info) && file.exists(info_file)) {
    sample_info <- utils::read.csv(info_file, stringsAsFactors = FALSE,
                                   colClasses = c(sample_id = "character"),
                                   check.names = FALSE)
  }
  spectra <- lapply(files, function(f) {
    ls_read_spectrum(f, ...)
  })

  ls_dataset(spectra, sample_info = sample_info)
}

#' Read a LIBS Spectrum from CSV (Convenience Wrapper)
#'
#' @param path Character. Path to CSV file.
#' @param ... Additional arguments passed to [ls_read_spectrum()].
#' @return A `libs_spectrum` object.
#' @examples
#' tmp <- tempfile(fileext = ".csv")
#' wl <- seq(200, 900, length.out = 100)
#' utils::write.csv(data.frame(wavelength = wl,
#'                             intensity = exp(-((wl - 393)^2) / 2)),
#'                  tmp, row.names = FALSE)
#' spec <- ls_read_csv(tmp, verbose = FALSE)
#' unlink(tmp)
#' @export
ls_read_csv <- function(path, ...) {
  ls_read_spectrum(path, format = "csv", ...)
}

# Internal helpers

#' @keywords internal
#' @noRd
.pick_col <- function(df, col) {
  if (length(col) != 1L || anyNA(col)) {
    cli::cli_abort("Wavelength column must be a single non-missing index or name.")
  }
  if (is.character(col)) {
    if (!col %in% names(df)) {
      cli::cli_abort("Column {.val {col}} not found.")
    }
    return(df[[col]])
  }
  if (is.numeric(col)) {
    if (!is.finite(col) || col != trunc(col) || col < 1 || col > ncol(df)) {
      cli::cli_abort("Column index {.val {col}} out of range.")
    }
    return(df[[col]])
  }
  cli::cli_abort("Column index must be character or numeric.")
}

#' @keywords internal
#' @noRd
.pick_cols <- function(df, cols) {
  if (!length(cols) || anyNA(cols) || anyDuplicated(cols)) {
    cli::cli_abort("Intensity columns must be non-empty, unique, non-missing indices or names.")
  }
  if (is.character(cols)) {
    missing_cols <- setdiff(cols, names(df))
    if (length(missing_cols) > 0) {
      cli::cli_abort("Columns not found: {.val {missing_cols}}")
    }
    return(df[, cols, drop = FALSE])
  }
  if (is.numeric(cols)) {
    if (length(cols) == 1 && cols == 2 && ncol(df) > 2) {
      cols <- 2:ncol(df)
    }
    bad <- !is.finite(cols) | cols != trunc(cols) | cols < 1 | cols > ncol(df)
    if (any(bad)) {
      cli::cli_abort("Column index out of range: {.val {cols[bad]}}")
    }
    return(df[, cols, drop = FALSE])
  }
  cli::cli_abort("Intensity column index must be character or numeric.")
}


.check_input_file <- function(path) {
  if (!is.character(path) || length(path) != 1L || is.na(path) ||
      !nzchar(path) || !file.exists(path) || dir.exists(path)) {
    cli::cli_abort("File not found or not a regular input file: {.val {path}}")
  }
}

.numeric_column <- function(x, name) {
  out <- suppressWarnings(as.numeric(as.character(x)))
  if (any(!is.finite(out))) {
    cli::cli_abort("The {name} column contains missing, non-numeric, or infinite values; no rows were discarded.")
  }
  out
}

.read_csv_metadata <- function(lines) {
  prefix <- "# libscanR-json-v1: "
  encoded <- lines[startsWith(lines, prefix)]
  if (length(encoded) > 1L) cli::cli_abort("Duplicate libscanR metadata headers.")
  if (length(encoded)) {
    payload <- tryCatch(jsonlite::fromJSON(substring(encoded, nchar(prefix) + 1L),
                                          simplifyDataFrame = FALSE,
                                          simplifyMatrix = FALSE),
                        error = function(e) cli::cli_abort("Invalid libscanR JSON metadata."))
    if (!is.list(payload) || anyDuplicated(names(payload)) ||
        !all(c("metadata", "baseline") %in% names(payload))) {
      cli::cli_abort("Invalid libscanR metadata structure.")
    }
    .check_metadata(payload$metadata)
    return(payload)
  }
  # Read earlier scalar comment headers as text; never evaluate file contents.
  comments <- grep("^# [^:]+: ", lines, value = TRUE)
  keys <- sub("^# ([^:]+): .*", "\\1", comments)
  values <- sub("^# [^:]+: ", "", comments)
  if (anyDuplicated(keys)) cli::cli_abort("Duplicate metadata keys.")
  list(metadata = stats::setNames(as.list(values), keys), baseline = NULL)
}

.read_spectral_table <- function(lines, delim = ",", header = NULL) {
  lines <- lines[nzchar(trimws(lines)) & !grepl("^\\s*#", lines)]
  if (!length(lines)) cli::cli_abort("No spectral table found.")
  con <- textConnection(lines)
  on.exit(close(con), add = TRUE)
  counts <- utils::count.fields(con, sep = delim, comment.char = "")
  if (anyNA(counts) || length(unique(counts)) != 1L) {
    cli::cli_abort("Spectral table rows have inconsistent column counts; no rows were discarded.")
  }
  if (is.null(header)) {
    first <- strsplit(lines[1], if (delim == "") "[[:space:]]+" else delim,
                      fixed = delim != "")[[1]]
    first <- gsub('^"|"$', "", trimws(first))
    header <- !all(is.finite(suppressWarnings(as.numeric(first))))
  }
  df <- tryCatch(utils::read.table(text = lines, header = header, sep = delim,
                                   stringsAsFactors = FALSE, check.names = FALSE,
                                   comment.char = "", fill = FALSE,
                                   row.names = NULL, colClasses = "character"),
                 error = function(e) cli::cli_abort("Invalid spectral table: {conditionMessage(e)}"))
  if (nrow(df) < 2L || ncol(df) < 2L || anyDuplicated(names(df))) {
    cli::cli_abort("A spectral table needs at least two channels and two uniquely named columns.")
  }
  df
}
