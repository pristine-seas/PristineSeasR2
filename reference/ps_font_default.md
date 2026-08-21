# The Pristine Seas house typeface

Returns the first of Inter, Helvetica Neue, Helvetica, Arial that is
both installed **and** able to render bold as a distinct face, falling
back to `"sans"`. Inter is preferred where it qualifies — it is the
closest freely available stand-in for National Geographic's Geograph,
with tighter apertures and better numerals than Helvetica.

Used as the default `base_family` for
[`theme_ps()`](https://pristine-seas.github.io/PristineSeasR2/reference/theme_ps.md)
and
[`theme_ps_map()`](https://pristine-seas.github.io/PristineSeasR2/reference/theme_ps_map.md).

## Usage

``` r
ps_font_default()
```

## Value

A single font family name.

## Why bold is checked

Both themes build their hierarchy on weight — bold titles, bold legend
titles, bold facet strips — against regular body text. Many systems ship
Inter as a *variable* font in a single file, where a request for bold
resolves to the same file and index as regular. Nothing errors; every
title just renders at regular weight and the hierarchy disappears.
Rather than let that happen silently, a family that cannot deliver bold
is skipped in favour of the next candidate. Install a static Inter build
(Regular + Bold as separate files) to get Inter back.

## Rendering

A named family only survives on a device with access to system fonts.
Raster devices generally have it — **ragg** resolves through the same
`systemfonts` lookup used here, and on macOS the built-in
`png(type = "quartz")` does too. The one that bites is
[`pdf()`](https://rdrr.io/r/grDevices/pdf.html), which R opens by
default when no device is active (a bare `Rscript`, for instance): it
matches against the PostScript font database rather than against the
system, and under grid — so under every ggplot — a family it does not
hold is a hard error, not a substitution. Rather than let that turn
every PDF export into a failure, resolving the family also registers it
with [`pdf()`](https://rdrr.io/r/grDevices/pdf.html), aliased onto
Helvetica's metrics: type comes out Helvetica rather than Inter, which
is the substitution the device would have made if it could, and the
figure draws. Cairo-based
[`png()`](https://rdrr.io/r/grDevices/png.html) on Linux and CI is
likewise patchier.

In practice:
[`ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html) in
ggplot2 \>= 4.0 already uses ragg when it is installed, so exports are
fine without being told. Inline figures are the ones worth setting,
since knitr defaults to grDevices `png` —
`knitr: opts_chunk: dev: ragg_png` in the document YAML.

## Examples

``` r
ps_font_default()
#> [1] "sans"
```
