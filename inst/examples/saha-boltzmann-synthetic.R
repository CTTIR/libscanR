# Analytical demonstration only: fictional transitions X/Y, no tissue or instrument data.
# Run after installing libscanR:
# source(system.file("examples", "saha-boltzmann-synthetic.R", package = "libscanR"))
# inputs <- saha_synthetic_example()
# result <- do.call(libscanR::ls_saha_boltzmann, inputs)
# Expected temperature 10000 K; relative number fractions X=0.7, Y=0.3.
saha_synthetic_example <- function(intensity_scale = c("energy", "photon"), gain = 1) {
  intensity_scale <- match.arg(intensity_scale)
  atomic <- utils::read.csv(system.file("extdata", "saha_synthetic_lines.csv",
                                        package = "libscanR"), stringsAsFactors = FALSE)
  wavelength <- seq(500, 600, by = 0.05)
  intensity <- numeric(length(wavelength))
  for (i in seq_len(nrow(atomic))) {
    # Unit-area compact triangular peaks, isolated by at least 10 nm.
    area <- atomic[[paste0("integrated_", intensity_scale)]][i] * gain
    shape <- pmax(0, 1 - abs(wavelength - atomic$wavelength_nm[i]) / 0.2) / 0.2
    intensity <- intensity + area * shape
  }
  list(x = libscanR::ls_spectrum(wavelength, intensity,
                                metadata = list(sample_id = "synthetic-two-stage-LTE",
                                                wavelength_medium = "vacuum", simulated = TRUE)),
       elements = c("X", "Y"), lines_nm = list(X = c(520, 530, 540), Y = c(560, 570, 580)),
       electron_density = 1e17, window_nm = 0.5, atomic_data = atomic,
       partition_functions = list(X = list(neutral = 2, ionized = 3),
                                    Y = list(neutral = 4, ionized = 5)),
       ionization_energies_ev = c(X = 7, Y = 9), intensity_scale = intensity_scale,
       verbose = FALSE)
}
