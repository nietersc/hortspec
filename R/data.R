#' ASTM G173-03 Reference Solar Spectra Derived from SMARTS v. 2.9.2
#'
#' A dataset containing the standard table for reference solar spectral irradiance:
#' Direct + circumsolar
#'
#' @format A data frame with 1701 rows and 2 variables:
#' \describe{
#'   \item{wavelength}{Wavelength in nanometers (nm)}
#'   \item{w_m2}{Irradiance value (W/m^2/nm)}
#'
#' }
#' @source \url{https://store.astm.org/g0173-03r20.html}
"astm_solar_data"

#' LED Spectrum Data
#'
#' Spectral distribution data for a 9-channel LED used in horticultural lighting.
#'
#' @format A data frame with 481 rows and 2 variables:
#' \describe{
#'   \item{wavelength}{Wavelength in nm}
#'   \item{w_m2}{Irradiance value (W/m^2/nm)}
#' }
"led_spectrum_data"
