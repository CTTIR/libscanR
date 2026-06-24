# Spatial Elemental Mapping

[![R-CMD-check](https://github.com/CTTIR/libscanR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/CTTIR/libscanR/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/CTTIR/libscanR/actions/workflows/pkgdown.yaml/badge.svg)](https://cttir.github.io/libscanR/)
[![CRAN
status](https://www.r-pkg.org/badges/version/libscanR)](https://CRAN.R-project.org/package=libscanR)
[![Codecov test
coverage](https://codecov.io/gh/CTTIR/libscanR/branch/main/graph/badge.svg)](https://app.codecov.io/gh/CTTIR/libscanR?branch=main)
[![CRAN
downloads](https://cranlogs.r-pkg.org/badges/libscanR)](https://cran.r-project.org/package=libscanR)
[![CRAN downloads
total](https://cranlogs.r-pkg.org/badges/grand-total/libscanR)](https://cran.r-project.org/package=libscanR)
[![License:
MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

``` r

library(libscanR)
```

## Raster scan dataset

``` r

ds <- ls_example_data("spatial")
ds
```

The simulated tissue section has:

- A left-to-right **Ca** gradient (decreasing)
- A top-to-bottom **Fe** gradient (increasing)
- A **Zn**-enriched hotspot simulating a tumor region

## Build a single elemental map

``` r

m_ca <- ls_build_map(ds, "Ca", 393.37)
ls_plot_map(m_ca)
```

![](spatial-mapping_files/figure-html/single-1.png)

## Multi-element panel

``` r

maps <- ls_map_elements(ds, c("Ca", "Fe", "Zn"),
                        c(Ca = 393.37, Fe = 371.99, Zn = 213.86))
ls_plot_map_panel(maps)
```

![](spatial-mapping_files/figure-html/panel-1.png)

## Applying a calibration to the map

``` r

cal_ds <- ls_example_data("calibration")
cal <- ls_calibrate(cal_ds, "Ca", 393.37,
                    concentrations = cal_ds$sample_info$concentration,
                    verbose = FALSE)
m_cal <- ls_build_map(ds, "Ca", 393.37, calibration = cal)
ls_plot_map(m_cal)
```

![](spatial-mapping_files/figure-html/calib-1.png)

## Hotspot detection

``` r

zn <- ls_build_map(ds, "Zn", 213.86)
hot_idx <- which(zn$values > stats::quantile(zn$values, 0.9))
head(data.frame(x = zn$x[hot_idx],
                y = zn$y[hot_idx],
                zn = round(zn$values[hot_idx], 1)))
#>    x y   zn
#> 1  8 3  9.5
#> 2  8 4  9.9
#> 3 10 4  9.1
#> 4  6 5 10.7
#> 5  9 5 11.3
#> 6  5 6  9.8
```
