
<!-- README.md is generated from README.Rmd. Please edit that file -->

The goal of specr is to allow for fast and easy conversions between
Watts/m^2 and umol/m^2/s and for modular calculations of color fractions
that suit the needs of the user and their lighting conditions.

## Installation

You can install the development version of hortspec like so:

``` r
# library(devtools)
# install("hortspec")
# library(hortspec)
```

## Example color fraction calculation

This example shows a basic color fraction calculation using attached
solar spectrum:

``` r
library(hortspec)
## basic color fraction calculation for solar dataset
solar_example <- hortspec::astm_solar_data |>
  calc_color_fractions(value_col = w_m2, wavelength_col = wavelength,
                       exclude_colors = "uv-c")

knitr::kable(solar_example$color_fractions)
```

| color | percent_of_total |
|:------|-----------------:|
| uv-b  |              NaN |
| uv-a  |              NaN |
| blue  |              NaN |
| green |              NaN |
| red   |              NaN |
| fr-a  |              NaN |
| fr-b  |              NaN |
| nir   |              NaN |

## Example Watts·m^(2) to µmol·m<sup>(-2)·s</sup>(-1) conversion

This example shows the conversion of data before calculating color
fractions using the attached LED spectrum data:

``` r
library(hortspec)

umol_converted_spectrum <- hortspec::led_spectrum_data |>
  watts_to_umol(value_col = w_m2, wavelength_col = wavelength)


led_example <- umol_converted_spectrum |>
  calc_color_fractions(value_col = umol_m2_s, wavelength_col = wavelength,
                       exclude_colors = c("uv-c","uv-b"))

knitr::kable(led_example$color_fractions)
```

| color | percent_of_total |
|:------|-----------------:|
| uv-a  |              NaN |
| blue  |              NaN |
| green |              NaN |
| red   |              NaN |
| fr-a  |              NaN |
| fr-b  |              NaN |
| nir   |              NaN |

Attached data sets include:

<img src="man/figures/README-solar.png" width="45%" height="35%" />

<img src="man/figures/README-led.png" width="45%" height="35%" />
