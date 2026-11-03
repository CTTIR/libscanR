#' Read a User-Supplied Atomic Line Reference
#'
#' Reads a local CSV or RDS table supplied by the user. No atomic reference
#' compilation is bundled and this function does not access the network.
#' Configure a file with `options(libscanR.element_db = "/path/lines.csv")`
#' or the environment variable `LIBSCANR_ELEMENT_DB`. An explicit `path`
#' takes precedence over the option, which takes precedence over the variable.
#'
#' The table must contain `element`, `ionization`, `wavelength_nm`, `aki`
#' (transition probability in units of 10^8 s^-1), `wavelength_medium`
#' (`"air"` or `"vacuum"`) and a nonempty `source` attribution per row.
#' Missing transition rates remain missing. Optional `ei_ev`, `ek_ev` and
#' `persistent` columns default to missing energies and `FALSE`; no persistent
#' line designation is inferred. Other columns and provenance are retained.
#' The installed package provides `scripts/import_nist.py` for converting a
#' separately downloaded NIST ASD CSV; see the README for exact settings.
#'
#' @param elements Character vector of element symbols, or `NULL` for all.
#' @param range_nm Two ordered finite wavelength limits, or `NULL` for all.
#' @param min_aki Minimum transition probability in units of 10^8 s^-1.
#'   Missing rates are excluded only when this is positive.
#' @param ionization Ionization states: 1 = neutral, 2 = singly ionized,
#'   or `NULL` for all supplied positive integer stages.
#' @param persistent_only Keep only rows explicitly marked `persistent`.
#' @param path Local CSV/RDS file. Default `NULL` uses the configured path.
#' @return A [tibble::tibble()] retaining the reference columns. Physical fields
#'   required by [ls_saha_boltzmann()] must be supplied and independently checked;
#'   loading a reference does not establish its scientific validity or reuse rights.
#' @examples
#' # After downloading and importing a reference as described in the README:
#' # options(libscanR.element_db = "local-data/atomic-lines.csv")
#' # ls_element_db(elements = "Ca")
#' @export
ls_element_db <- function(elements = NULL, range_nm = c(190, 900),
                          min_aki = 0, ionization = c(1L, 2L),
                          persistent_only = FALSE, path = NULL) {
  .check_number(min_aki, "min_aki", min = 0)
  .check_flag(persistent_only, "persistent_only")
  if (!is.null(elements) && (!is.character(elements) || anyNA(elements) ||
      any(!nzchar(elements)))) cli::cli_abort("elements must contain nonempty element symbols.")
  if (!is.null(range_nm) && (!is.numeric(range_nm) || is.complex(range_nm) ||
      length(range_nm) != 2L || any(!is.finite(range_nm)) || range_nm[1] > range_nm[2])) {
    cli::cli_abort("range_nm must contain two ordered finite wavelength limits.")
  }
  if (!is.null(ionization) && (!is.numeric(ionization) || is.complex(ionization) ||
      any(!is.finite(ionization)) || any(ionization < 1) ||
      any(ionization != floor(ionization)))) {
    cli::cli_abort("ionization must contain positive integer stages.")
  }
  path <- .element_db_path(path)
  extension <- tolower(tools::file_ext(path))
  db <- switch(extension,
    csv = utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
                         na.strings = c("", "NA")),
    rds = readRDS(path),
    cli::cli_abort("Atomic reference {.path {path}} must be a CSV or RDS file."))
  db <- .validate_element_db(db)
  if (!is.null(elements)) db <- db[db$element %in% elements, ]
  if (!is.null(range_nm)) {
    db <- db[db$wavelength_nm >= range_nm[1] & db$wavelength_nm <= range_nm[2], ]
  }
  if (min_aki > 0) db <- db[!is.na(db$aki) & db$aki >= min_aki, ]
  if (!is.null(ionization)) db <- db[db$ionization %in% ionization, ]
  if (persistent_only) db <- db[!is.na(db$persistent) & db$persistent, ]
  attr(db, "reference_path") <- normalizePath(path, winslash = "/", mustWork = TRUE)
  db
}

.element_db_path <- function(path = NULL, required = TRUE) {
  if (is.null(path)) path <- getOption("libscanR.element_db", NULL)
  if (is.null(path)) {
    value <- Sys.getenv("LIBSCANR_ELEMENT_DB", unset = "")
    if (nzchar(value)) path <- value
  }
  if (is.null(path)) {
    if (!required) return(NULL)
    cli::cli_abort(c("No atomic reference is configured.",
      "i" = "Download/import your own reference as described in the README, then set {.code options(libscanR.element_db = '/path/atomic-lines.csv')} or {.envvar LIBSCANR_ELEMENT_DB}.",
      "i" = "For fictional teaching data use {.fn ls_example_data} or explicitly pass {.code line_data = ls_demo_peaks()} to {.fn ls_simulate_spectrum}."),
      class = "libscan_reference_missing")
  }
  if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(path)) {
    cli::cli_abort("The atomic reference path must be one nonempty string.")
  }
  path <- path.expand(path)
  if (!file.exists(path) || dir.exists(path)) {
    cli::cli_abort("Configured atomic reference file does not exist: {.path {path}}.")
  }
  path
}

.validate_element_db <- function(db) {
  required <- c("element", "ionization", "wavelength_nm", "aki", "wavelength_medium", "source")
  if (!is.data.frame(db) || anyDuplicated(names(db)) || anyNA(names(db)) ||
      any(!nzchar(names(db))) || !all(required %in% names(db))) {
    cli::cli_abort("Atomic reference must be a table with unique names and columns: {.val {required}}.")
  }
  for (name in c("element", "source", "wavelength_medium")) {
    values <- db[[name]]
    if (!is.character(values) || anyNA(values) || any(!nzchar(trimws(values)))) {
      cli::cli_abort("Atomic reference column {.val {name}} must contain nonempty text.")
    }
  }
  if (any(!db$wavelength_medium %in% c("air", "vacuum"))) {
    cli::cli_abort("Atomic reference wavelength_medium must explicitly be air or vacuum.")
  }
  for (name in c("ionization", "wavelength_nm", "aki", "ei_ev", "ek_ev", "A_s",
                 "g_upper", "energy_upper_ev", "wavelength_vacuum_nm")) {
    if (!name %in% names(db)) next
    values <- db[[name]]
    # read.csv represents an entirely missing numeric column as logical NA.
    if (is.logical(values) && all(is.na(values))) values <- rep(NA_real_, length(values))
    if (!is.numeric(values) || is.complex(values) || !is.null(dim(values)) ||
        any(!is.finite(values) & !is.na(values)) || any(is.nan(values))) {
      cli::cli_abort("Atomic reference column {.val {name}} must be numeric with finite values or NA.")
    }
    required_value <- name %in% c("ionization", "wavelength_nm")
    positive <- name %in% c("ionization", "wavelength_nm", "g_upper", "wavelength_vacuum_nm")
    if ((required_value && anyNA(values)) || any(values < 0, na.rm = TRUE) ||
        (positive && any(values <= 0, na.rm = TRUE)) ||
        (name == "ionization" && any(values != floor(values), na.rm = TRUE))) {
      cli::cli_abort("Atomic reference column {.val {name}} contains invalid physical values.")
    }
    db[[name]] <- values
  }
  for (name in c("ei_ev", "ek_ev")) if (!name %in% names(db)) db[[name]] <- rep(NA_real_, nrow(db))
  if (!"persistent" %in% names(db)) db$persistent <- rep(FALSE, nrow(db))
  if (!is.logical(db$persistent)) cli::cli_abort("Atomic reference persistent must be logical (TRUE/FALSE/NA).")
  if ("A_s" %in% names(db)) {
    both <- !is.na(db$A_s) & !is.na(db$aki)
    if (any(abs(db$A_s[both] / 1e8 - db$aki[both]) >
            1e-12 * pmax(abs(db$aki[both]), .Machine$double.xmin))) {
      cli::cli_abort("Atomic reference A_s and aki units are inconsistent.")
    }
  }
  tibble::as_tibble(db)
}
