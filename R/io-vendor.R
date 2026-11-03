#' Read SciAps LIBS Data
#'
#' Parses output files from SciAps handheld LIBS analyzers (Z-series).
#' The SciAps export format typically includes metadata lines preceded by
#' `#` or a keyword header, followed by a wavelength/intensity table.
#'
#' @param path Character. Path to SciAps export file.
#' @param verbose Logical. Emit messages. Default `TRUE`.
#'
#' @return A `libs_spectrum` object with SciAps-specific metadata.
#'
#' @examples
#' # See vignette("getting-started") for realistic usage; this parser
#' # is best exercised against actual SciAps export files.
#' tmp <- tempfile(fileext = ".csv")
#' writeLines(c(
#'   "# SciAps Z-903",
#'   "# Serial: 12345",
#'   "# Gate Delay (us): 2.5",
#'   "wavelength,intensity",
#'   "200.0,50",
#'   "200.5,55",
#'   "201.0,52"
#' ), tmp)
#' spec <- ls_read_sciaps(tmp, verbose = FALSE)
#' unlink(tmp)
#' @export
ls_read_sciaps <- function(path, verbose = TRUE) {
  .check_input_file(path)
  .check_flag(verbose, "verbose")
  lines <- readLines(path, warn = FALSE)
  data_start <- .detect_data_start(lines)

  header <- lines[seq_len(max(0, data_start - 1))]
  meta <- .parse_sciaps_header(header)

  df <- .read_spectral_table(lines[seq.int(data_start, length(lines))])
  wl <- .numeric_column(df[[1]], "wavelength")
  intensity <- t(vapply(df[, -1, drop = FALSE], .numeric_column,
                         numeric(nrow(df)), name = "intensity"))
  dimnames(intensity) <- NULL

  meta$source_file <- path
  meta$vendor <- "SciAps"
  meta$sample_id <- meta$sample_id %||% tools::file_path_sans_ext(basename(path))

  spec <- ls_spectrum(wavelength = wl, intensity = intensity,
                      metadata = meta)
  if (verbose) {
    cli::cli_inform(c("v" = "Read SciAps file: {spec$n_channels} channels, {spec$n_shots} shot(s)."))
  }
  spec
}

#' Read Applied Spectra / Aurora Data
#'
#' Parses output from Applied Spectra J200 and Aurora LIBS systems.
#' Applied Spectra files commonly have wavelength in the first column and
#' shots in subsequent columns, optionally with a few header lines.
#'
#' @param path Character. Path to export file (.csv or .asc).
#' @param verbose Logical. Default `TRUE`.
#'
#' @return A `libs_spectrum` object.
#'
#' @examples
#' tmp <- tempfile(fileext = ".csv")
#' writeLines(c(
#'   "Applied Spectra J200",
#'   "Model,J200",
#'   "wl,shot1,shot2",
#'   "200.0,50,52",
#'   "200.5,55,58",
#'   "201.0,52,50"
#' ), tmp)
#' spec <- ls_read_aurora(tmp, verbose = FALSE)
#' unlink(tmp)
#' @export
ls_read_aurora <- function(path, verbose = TRUE) {
  .check_input_file(path)
  .check_flag(verbose, "verbose")
  lines <- readLines(path, warn = FALSE)
  data_start <- .detect_data_start(lines)

  header <- lines[seq_len(max(0, data_start - 1))]
  meta <- list()
  for (h in header) {
    if (grepl("Model", h, ignore.case = TRUE)) {
      meta$instrument_model <- trimws(sub(".*[,:\t]", "", h))
    }
  }

  df <- .read_spectral_table(lines[seq.int(data_start, length(lines))])
  wl <- .numeric_column(df[[1]], "wavelength")
  intensity <- t(vapply(df[, -1, drop = FALSE], .numeric_column,
                         numeric(nrow(df)), name = "intensity"))
  dimnames(intensity) <- NULL

  meta$source_file <- path
  meta$vendor <- "Applied Spectra"
  meta$sample_id <- tools::file_path_sans_ext(basename(path))

  spec <- ls_spectrum(wavelength = wl, intensity = intensity, metadata = meta)
  if (verbose) {
    cli::cli_inform(c("v" = "Read Applied Spectra file: {spec$n_channels} channels, {spec$n_shots} shot(s)."))
  }
  spec
}

#' Auto-Detect and Read LIBS Data
#'
#' Attempts to identify the file format (generic CSV, SciAps, Applied Spectra)
#' and dispatches to the correct reader. When `path` is a directory, delegates
#' to [ls_read_dir()].
#'
#' @param path Character. Path to spectrum file or directory.
#' @param verbose Logical. Default `TRUE`.
#'
#' @return A `libs_spectrum` or `libs_dataset` object.
#'
#' @examples
#' tmp <- tempfile(fileext = ".csv")
#' utils::write.csv(data.frame(wavelength = seq(200, 300, 1),
#'                             intensity = 1:101),
#'                  tmp, row.names = FALSE)
#' spec <- ls_read_auto(tmp, verbose = FALSE)
#' unlink(tmp)
#' @export
ls_read_auto <- function(path, verbose = TRUE) {
  if (dir.exists(path)) {
    return(ls_read_dir(path, verbose = verbose))
  }
  if (!file.exists(path)) {
    cli::cli_abort("Path not found: {.path {path}}")
  }
  head_lines <- readLines(path, n = 20, warn = FALSE)
  header_text <- paste(head_lines, collapse = " ")

  if (grepl("SciAps|Z-[0-9]{3}", header_text, ignore.case = TRUE)) {
    return(ls_read_sciaps(path, verbose = verbose))
  }
  if (grepl("Applied Spectra|Aurora|J200", header_text, ignore.case = TRUE)) {
    return(ls_read_aurora(path, verbose = verbose))
  }
  ls_read_spectrum(path, verbose = verbose)
}

# Internal helpers

#' @keywords internal
#' @noRd
.detect_data_start <- function(lines) {
  # Prefer header line containing "wavelength" / "wave"
  for (i in seq_along(lines)) {
    if (grepl('^\\s*"?(wl|wave(length)?(_nm)?)("?[,\\t ]|$)', lines[i], ignore.case = TRUE)) {
      return(i)
    }
  }
  # Fall back to first numeric-looking line not starting with '#'
  for (i in seq_along(lines)) {
    line <- trimws(lines[i])
    if (!nzchar(line)) next
    if (substr(line, 1, 1) == "#") next
    first <- substr(line, 1, 1)
    if (first %in% c("0","1","2","3","4","5","6","7","8","9","+","-",".")) {
      return(i)
    }
  }
  1L
}

#' @keywords internal
#' @noRd
.parse_sciaps_header <- function(header) {
  meta <- list()
  for (h in header) {
    h <- sub("^#\\s*", "", h)
    if (grepl("Serial", h, ignore.case = TRUE)) {
      meta$serial_number <- trimws(sub(".*?:\\s*", "", h))
    } else if (grepl("Gate Delay", h, ignore.case = TRUE)) {
      m <- regmatches(h, regexpr("[0-9.]+", h))
      if (length(m) > 0) meta$gate_delay_us <- as.numeric(m)
    } else if (grepl("Integration", h, ignore.case = TRUE)) {
      m <- regmatches(h, regexpr("[0-9.]+", h))
      if (length(m) > 0) meta$integration_time_us <- as.numeric(m)
    } else if (grepl("Model", h, ignore.case = TRUE)) {
      meta$instrument_model <- trimws(sub(".*?:\\s*", "", h))
    }
  }
  meta
}

`%||%` <- function(a, b) if (is.null(a)) b else a
