# Spatial Elemental Mapping

![libscanR logo](figures/logo.svg)![libscanR
logo](figures/logo-dark.svg)

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

![A 20 by 20 fictional raster map of integrated response near 393.37 nm.
The viridis legend ranges from low purple to high yellow; values are
peak area, not calibrated
concentration.](spatial-mapping_files/figure-html/single-1.png)

## Multi-element panel

``` r

maps <- ls_map_elements(ds, c("Ca", "Fe", "Zn"),
                        c(Ca = 393.37, Fe = 371.99, Zn = 213.86))
ls_plot_map_panel(maps)
```

![Three fictional raster maps labelled Ca, Fe and Zn, each showing
integrated response at its specified teaching wavelength and its own
colour scale.](spatial-mapping_files/figure-html/panel-1.png)

## Applying a calibration to the map

``` r

cal_ds <- ls_example_data("calibration")
cal <- ls_calibrate(cal_ds, "Ca", 393.37,
                    concentrations = cal_ds$sample_info$concentration,
                    verbose = FALSE)
m_cal <- ls_build_map(ds, "Ca", 393.37, calibration = cal)
ls_plot_map(m_cal)
```

![The fictional Ca-labelled raster map after applying the teaching
calibration, with predicted concentration in ppm. This demonstrates
model application, not validated tissue
concentrations.](spatial-mapping_files/figure-html/calib-1.png)

## Hotspot detection

``` r

zn <- ls_build_map(ds, "Zn", 213.86)
hot_idx <- which(zn$values > stats::quantile(zn$values, 0.9))
head(data.frame(x = zn$x[hot_idx],
                y = zn$y[hot_idx],
                zn = round(zn$values[hot_idx], 1)))
#>    x y  zn
#> 1  7 2 5.4
#> 2 10 2 3.8
#> 3  7 3 4.7
#> 4  8 3 5.3
#> 5 16 3 4.8
#> 6 17 3 4.1
```
