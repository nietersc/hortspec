#' Watts to micromoles conversion
#'
#' Convert Watts/meter^2/nm to Micromols/meter^2/second/nm
#' @param df a dataframe containing spectroradiometer data
#' @param value_col the column in the dataframe with the intensity emission data. Must be **numeric**
#' @param wavelength_col the column in the dataframe with the wavelength data. Must be **numeric**
#' @return The spectroradiometer reading in Micromols/meter^2/second/nm
#' @examples
#' umol_converted <- watts_to_umol(data = astm_solar_data, value_col = w_m2, wavelength_col = wavelength)
#' @export

watts_to_umol <- function(df, value_col, wavelength_col) {

  value_col = rlang::enquo(value_col)
  wavelength_col = rlang::enquo(wavelength_col)

  # Check if specified columns exist in the data frame
  if (!(rlang::quo_name(value_col) %in% names(df)) || !(rlang::quo_name(wavelength_col) %in% names(df))) {
    stop("Specified value or wavelength column does not exist in the data frame.")
  }

  # Check if the specified columns are numeric
  if (!is.numeric(df[[rlang::quo_name(value_col)]]) || !is.numeric(df[[rlang::quo_name(wavelength_col)]])) {
    stop("Both value and wavelength columns must be numeric.")
  }


  df |>
    dplyr::mutate(
      h = 6.62607015 *(10^(-34)),# Planck's Constant
      c = 3.0 * (10^(8)), # Speed of light
      wavelength = !!wavelength_col, #wavelength in nanometers
      wavelength_m = wavelength/(10^9), #wavelength in meters
      E = h * c / wavelength_m, # Joules per photon at each lambda
      A = 6.0221408 * 10^23, # Avagadro's Number
      J_mol = E * A, # Joules/mol of photons
      umol_J = 1 / (J_mol/(10^6)), # divide J_mol by 10^6 and take the inverse (1/x)
      umol_m2_s = umol_J * !!value_col #Multiply Watts/m^2 (= Joules/m^2/second) by umol/Joule to get final answer
  ) |>
    dplyr::select(-c(h, c, wavelength_m, E,
                     A, J_mol, umol_J))

}
