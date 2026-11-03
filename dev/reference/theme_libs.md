# LIBS Theme for ggplot2

A clean publication-ready theme for LIBS spectral plots.

## Usage

``` r
theme_libs(base_size = 12)
```

## Arguments

- base_size:

  Numeric. Base font size in points. Default 12.

## Value

A ggplot2 theme object.

## Examples

``` r
ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) +
  ggplot2::geom_point() + theme_libs()
```
