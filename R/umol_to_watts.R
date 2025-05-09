#' Micromoles to Watts conversion
#'
#' Convert Micromols/meter^2/second/nm to Watts/meter^2/nm
#' @param df a dataframe containing spectroradiometer data
#' @param value_col the column in the dataframe with the intensity emission data. Must be **numeric**
#' @param wavelength_col the column in the dataframe with the wavelength data. Must be **numeric**
#' @return The spectroradiometer reading in Watts/meter^2/nm
#' @examples 
#' umol_converted <- umol_to_watts(data = led_spectrum_data, value_col = umol_m2_s, wavelength_col = wavelength)
#' @export

umol_to_watts <- function(df, value_col, wavelength_col) {
  
  value_col = enquo(value_col)
  wavelength_col = enquo(wavelength_col)
  
  # Check if specified columns exist in the data frame
  if (!(quo_name(value_col) %in% names(df)) || !(quo_name(wavelength_col) %in% names(df))) {
    stop("Specified value or wavelength column does not exist in the data frame.")
  }
  
  # Check if the specified columns are numeric
  if (!is.numeric(df[[quo_name(value_col)]]) || !is.numeric(df[[quo_name(wavelength_col)]])) {
    stop("Both value and wavelength columns must be numeric.")
  }
  
  df |>
    dplyr::mutate(
      h = 6.62607015 * (10^(-34)), # Planck's Constant
      c = 3.0 * (10^(8)),          # Speed of light
      wavelength = !!wavelength_col, # wavelength in nanometers
      wavelength_m = wavelength / (10^9), # wavelength in meters
      E = h * c / wavelength_m,    # Joules per photon at each wavelength
      A = 6.0221408 * 10^23,            # Avogadro's Number
      J_mol = E * A,               # Joules/mol of photons
      umol_J = 1 / (J_mol / (10^6)), # Micro moles per Joule
      watts_m2 = !!value_col / umol_J # Convert µmol to W/m^2 by dividing by umol/J
    ) |>
    dplyr::select(-c(h, c, wavelength_m, E, A, J_mol, umol_J))
}
