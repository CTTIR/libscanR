#!/usr/bin/env Rscript
# fingerprint.R - deterministic sha256 fingerprint of R/ source files.
# Used to prove that test-only work leaves package behavior (source) unchanged.
# Usage:
#   Rscript fingerprint.R          # print fingerprint table + combined digest
#   Rscript fingerprint.R write    # write _coverage/fingerprint.txt
#   Rscript fingerprint.R compare  # compare against _coverage/fingerprint.txt

suppressWarnings(suppressMessages({
  stopifnot(requireNamespace("digest", quietly = TRUE))
}))

r_files <- sort(list.files("R", pattern = "\\.R$", full.names = TRUE))

fp <- vapply(r_files, function(f) {
  # Read as raw bytes, normalize CRLF -> LF so the digest is OS-independent.
  raw <- readBin(f, what = "raw", n = file.info(f)$size)
  txt <- rawToChar(raw)
  txt <- gsub("\r\n", "\n", txt, fixed = TRUE)
  digest::digest(charToRaw(txt), algo = "sha256", serialize = FALSE)
}, character(1))

tab <- data.frame(file = r_files, sha256 = unname(fp), stringsAsFactors = FALSE)
tab <- tab[order(tab$file), ]
combined <- digest::digest(paste(tab$file, tab$sha256, collapse = "\n"),
                           algo = "sha256", serialize = FALSE)

mode <- if (length(commandArgs(TRUE))) commandArgs(TRUE)[1] else "print"
out_file <- file.path("_coverage", "fingerprint.txt")

render <- function() {
  lines <- c(sprintf("%s  %s", tab$sha256, tab$file),
             sprintf("COMBINED  %s", combined))
  paste(lines, collapse = "\n")
}

if (identical(mode, "write")) {
  dir.create("_coverage", showWarnings = FALSE)
  writeLines(render(), out_file)
  cat("Wrote", out_file, "\n")
  cat("COMBINED", combined, "\n")
} else if (identical(mode, "compare")) {
  if (!file.exists(out_file)) stop("No baseline fingerprint at ", out_file)
  prev <- paste(readLines(out_file, warn = FALSE), collapse = "\n")
  now <- render()
  if (identical(prev, now)) {
    cat("FINGERPRINT: IDENTICAL\n")
    cat("COMBINED", combined, "\n")
  } else {
    cat("FINGERPRINT: DIFFERENT\n")
    prev_l <- strsplit(prev, "\n")[[1]]
    now_l <- strsplit(now, "\n")[[1]]
    diffs <- union(setdiff(prev_l, now_l), setdiff(now_l, prev_l))
    cat(paste(diffs, collapse = "\n"), "\n")
    quit(status = 1)
  }
} else {
  cat(render(), "\n")
}
