# Wavelength-Based Color Scale

Maps wavelength values (nm) to approximate visible-light colors for
intuitive spectral visualization. Below 380 nm: UV purple; above 780 nm:
deep red.

## Usage

``` r
scale_color_wavelength(name = "Wavelength (nm)", ...)
```

## Arguments

- name:

  Character. Legend title. Default `"Wavelength (nm)"`.

- ...:

  Additional arguments passed to
  [`ggplot2::scale_color_gradientn()`](https://ggplot2.tidyverse.org/reference/scale_gradient.html).

## Value

A ggplot2 scale object.

## Examples

``` r
df <- data.frame(x = 1:5, y = 1:5, wl = c(200, 400, 550, 700, 850))
ggplot2::ggplot(df, ggplot2::aes(x, y, colour = wl)) +
  ggplot2::geom_point(size = 5) + scale_color_wavelength()
```
