
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
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
```

``` r

solar_example$color_fractions
#> # A tibble: 8 × 2
#>   color percent_of_total
#>   <fct>            <dbl>
#> 1 uv-b               NaN
#> 2 uv-a               NaN
#> 3 blue               NaN
#> 4 green              NaN
#> 5 red                NaN
#> 6 fr-a               NaN
#> 7 fr-b               NaN
#> 8 nir                NaN
```

``` r

test <- print(solar_example$parsed_dataframe)
#> # A tibble: 1,700 × 3
#>    wavelength trapz_est color
#>         <dbl>     <dbl> <chr>
#>  1        301         0 uv-b 
#>  2        302         0 uv-b 
#>  3        303         0 uv-b 
#>  4        304         0 uv-b 
#>  5        305         0 uv-b 
#>  6        306         0 uv-b 
#>  7        307         0 uv-b 
#>  8        308         0 uv-b 
#>  9        309         0 uv-b 
#> 10        310         0 uv-b 
#> # ℹ 1,690 more rows
```

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

print(led_example$color_fractions)
#> # A tibble: 7 × 2
#>   color percent_of_total
#>   <fct>            <dbl>
#> 1 uv-a               NaN
#> 2 blue               NaN
#> 3 green              NaN
#> 4 red                NaN
#> 5 fr-a               NaN
#> 6 fr-b               NaN
#> 7 nir                NaN
```

Attached data sets include:

<img src="man/figures/README-solar.png" width="45%" height="35%" />

<img src="man/figures/README-led.png" width="45%" height="35%" />
