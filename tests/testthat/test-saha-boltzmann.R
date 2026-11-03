saha_inputs <- function(scale = "energy", gain = 1) {
  env <- new.env(parent = globalenv())
  sys.source(system.file("examples", "saha-boltzmann-synthetic.R", package = "libscanR"), envir = env)
  env$saha_synthetic_example(scale, gain)
}

test_that("two-stage inference recovers independent high-precision forward data", {
  input <- saha_inputs()
  result <- do.call(ls_saha_boltzmann, input)
  expect_equal(result$temperature_k, rep(10000, 2), tolerance = 1e-8)
  expect_equal(result$concentration_rel, c(.7, .3), tolerance = 1e-10)
  expect_true(all(result$r_squared > 1 - 1e-12))
  expect_true(all(result$log_population_sd < 1e-10))
  diagnostics <- attr(result, "line_diagnostics")
  expect_equal(diagnostics$integrated_intensity, input$atomic_data$integrated_energy, tolerance = 1e-10)
  expect_false(attr(result, "assumptions")$experimentally_verified)
  expect_equal(attr(result, "assumptions")$normalized_over, c("X", "Y"))
})

test_that("photon and energy conventions and common instrument gain agree", {
  energy <- do.call(ls_saha_boltzmann, saha_inputs())
  photon <- do.call(ls_saha_boltzmann, saha_inputs("photon"))
  amplified <- do.call(ls_saha_boltzmann, saha_inputs(gain = 1e6))
  expect_equal(energy$concentration_rel, photon$concentration_rel, tolerance = 1e-10)
  expect_equal(energy$temperature_k, photon$temperature_k, tolerance = 1e-10)
  expect_equal(energy$concentration_rel, amplified$concentration_rel, tolerance = 1e-10)
})

test_that("electron density changes relative amounts through ion-stage balance", {
  input <- saha_inputs()
  input$temperature_k <- 10000
  first <- do.call(ls_saha_boltzmann, input)
  input$electron_density <- 1e18
  second <- do.call(ls_saha_boltzmann, input)
  golden <- jsonlite::fromJSON(test_path("fixtures", "saha", "golden.json"))
  r <- unlist(golden$ion_ratios)
  old_fraction <- c(1 / (1 + r[1]), r[2] / (1 + r[2]))
  new_fraction <- c(1 / (1 + r[1] / 10), (r[2] / 10) / (1 + r[2] / 10))
  amount <- c(.7, .3) * old_fraction / new_fraction
  expect_equal(second$concentration_rel, unname(amount / sum(amount)), tolerance = 1e-10)
  expect_gt(max(abs(second$concentration_rel - first$concentration_rel)), 0.1)
})

test_that("missing physics and ambiguous or unsupported measurements fail explicitly", {
  input <- saha_inputs()
  missing <- input
  missing$partition_functions <- NULL
  expect_error(do.call(ls_saha_boltzmann, missing), "Supply atomic_data")
  invalid <- input
  invalid$atomic_data$g_upper[1] <- 0
  expect_error(do.call(ls_saha_boltzmann, invalid), "invalid physical values")
  invalid <- input
  invalid$atomic_data <- rbind(invalid$atomic_data, invalid$atomic_data[1, ])
  expect_error(do.call(ls_saha_boltzmann, invalid), "exactly one")
  invalid <- input
  invalid$wavelength_medium <- "air"
  expect_error(do.call(ls_saha_boltzmann, invalid), "measured medium")
  invalid <- input
  invalid$x$intensity[,] <- 0
  expect_error(do.call(ls_saha_boltzmann, invalid), "positive finite integrated")
  invalid <- input
  invalid$atomic_data$energy_upper_ev[] <- 2
  expect_error(do.call(ls_saha_boltzmann, invalid), "distinct upper energies")
  invalid <- input
  invalid$atomic_data$energy_upper_ev <- 10 - invalid$atomic_data$energy_upper_ev
  expect_error(do.call(ls_saha_boltzmann, invalid), "slope is not negative")
  invalid <- input
  invalid$window_nm <- 12
  expect_error(do.call(ls_saha_boltzmann, invalid), "disjoint")
})

test_that("ambiguous metadata and contradictory atomic inputs cannot change fractions silently", {
  input <- saha_inputs()
  names(input$x$metadata)[names(input$x$metadata) == "wavelength_medium"] <- "wavelength_medium_unknown"
  expect_error(do.call(ls_saha_boltzmann, input), "Specify the measured wavelength_medium")
  input <- saha_inputs()
  input$atomic_data$wavelength_vacuum_nm[1:3] <- 2 * input$atomic_data$wavelength_vacuum_nm[1:3]
  expect_error(do.call(ls_saha_boltzmann, input), "consistent wavelength")
  input <- saha_inputs()
  input$partition_functions$X <- list(neutral = 2, neutral = 200, ionized = 3)
  expect_error(do.call(ls_saha_boltzmann, input), "unique neutral and ionized")
  input <- saha_inputs()
  input$ionization_energies_ev <- c(X = 7 + 1i, Y = 9)
  expect_error(do.call(ls_saha_boltzmann, input), "positive first ionization energies")
  input <- saha_inputs()
  input$atomic_data$energy_upper_ev[1] <- 0
  expect_error(do.call(ls_saha_boltzmann, input), "invalid physical values")
})

test_that("unrepresentable physical inputs and missing measured windows fail explicitly", {
  input <- saha_inputs()
  input$temperature_k <- 1e-307
  expect_error(do.call(ls_saha_boltzmann, input), "numerical range")
  input <- saha_inputs()
  input$temperature_k <- 1
  expect_error(do.call(ls_saha_boltzmann, input), "cannot be represented")
  input <- saha_inputs()
  # A gap in an otherwise finely sampled axis must not use a remote channel.
  keep <- abs(input$x$wavelength - 520) > 1
  input$x <- ls_spectrum(input$x$wavelength[keep], input$x$intensity[, keep],
                         metadata = input$x$metadata)
  expect_error(do.call(ls_saha_boltzmann, input), "at least three measured channels")
})
