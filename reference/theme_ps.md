# Pristine Seas ggplot2 theme

A clean, publication-ready ggplot2 theme

## Usage

``` r
theme_ps(base_size = 12, base_family = "Helvetica")
```

## Arguments

- base_size:

  Numeric. Base font size. Default is 12.

- base_family:

  Character. Base font family. Default is "Helvetica".

## Value

A ggplot2 theme object.

## Examples

``` r
library(ggplot2)
ggplot(mpg, aes(class, hwy)) +
  geom_boxplot(fill = "#0A9396", color = "white") +
  labs(title = "Fuel efficiency by car class") +
  theme_ps()

```
