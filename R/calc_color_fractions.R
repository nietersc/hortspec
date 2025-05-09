#' Color fraction calculation
#'
#' Takes spectroradiometer data and calculates the contributions of ultraviolet-c (uv-c, 100-280 nm),
#' ultraviolet-b (uv-b, 280-315 nm), ultraviolet-a, (uv-a, 315-400 nm), blue (400-500 nm), green (500-600 nm),
#' red (600-700 nm), far-red A (fr-a, 700-750 nm), far red B (fr-b, 750-800 nm), and near infrared (nir, 800-2500 nm) using
#' trapezoidal integration.
#' @param df a dataframe object with spectroradiometer data
#' @param value_col the column in the dataframe with the intensity emission data. Must be **numeric**
#' @param wavelength_col the column in the dataframe with the wavelength data. Must be **numeric** and wavelength increments
#' **must** be equal between all measurements.
#' @param  exclude_colors colors can be manually excluded from color fraction calculation if they are outside the scope
#' of wavelengths the user is interested in including
#' @return A list item containing the `summary` object with of the sum amounts in each color range and their percent contribtions
#' to the total and `parsed_colors` object with the transformed dataframe with negative values removed and with trapezoidal
#' estimates (if argument = TRUE) and the assigned color for each row of data.
#' @examples
#' color_summary <- calc_color_fractions(df = astm_solar_data,  value_col = watts_m2, wavelength_col = wavelength,
#'                                       calculate_trapz_est = FALSE, exclude_colors = c("uv-c","uv-b","nir"))
#' summary_table <- color_summary$summary
#' parsed_datafram <- color_summary$parsed_colors
#'
#' @export

calc_color_fractions <- function(df, value_col, wavelength_col, exclude_colors = NULL) {

  value_col <- rlang::enquo(value_col)
  wavelength_col <- rlang::enquo(wavelength_col)

  # Check if specified columns exist
  if (!(rlang::quo_name(value_col) %in% names(df)) || !(rlang::quo_name(wavelength_col) %in% names(df))) {
    stop("Specified value or wavelength column does not exist in the data frame.")
  }

  # Check if columns are numeric
  if (!is.numeric(df[[rlang::quo_name(value_col)]]) || !is.numeric(df[[rlang::quo_name(wavelength_col)]])) {
    stop("Both value and wavelength columns must be numeric.")
  }



  # Define full wavelength ranges for each color category
  ranges <- list(
    "uv-c" = seq(100, 279.99, by = 0.1),
    "uv-b" = seq(280, 314.99, by = 0.1),
    "uv-a" = seq(315, 399.99, by = 0.1),
    "blue" = seq(400, 499.99, by = 0.1),
    "green" = seq(500, 599.99, by = 0.1),
    "red" = seq(600, 699.99, by = 0.1),
    "fr-a" = seq(700, 749.99, by = 0.1),
    "fr-b" = seq(750, 799.99, by = 0.1),
    "nir" = seq(800, 2500, by = 0.1)
  )

  # Determine available colors based on data
  available_waves <- df[[rlang::quo_name(wavelength_col)]]
  available_colors <- c()
  for (color in names(ranges)) {
    range_waves <- ranges[[color]]
    if (any(available_waves %in% range_waves)) {
      available_colors <- c(available_colors, color)
    }
  }


  # Remove excluded colors
  if (!is.null(exclude_colors)) {
    available_colors <- dplyr::setdiff(available_colors, exclude_colors)
  }

  # Find missing ranges
  missing_colors <- dplyr::setdiff(names(ranges), available_colors)

  # Warn only if missing ranges are not all excluded
  if (length(missing_colors) > 0 &&
      (is.null(exclude_colors) || !all(missing_colors %in% exclude_colors))) {
    warning("Missing wavelength ranges for: ", paste(missing_colors, collapse = ", ", "Add to `exclude_colors` to remove warning."))
  }


  # Assign color based on wavelength, only if range exists
  assign_color <- function(wl) {
    if (wl >= 100 & wl <= 279.99) return("uv-c")
    if (wl >= 280 & wl <= 314.99) return("uv-b")
    if (wl >= 315 & wl <= 399.99) return("uv-a")
    if (wl >= 400 & wl <= 499.99) return("blue")
    if (wl >= 500 & wl <= 599.99) return("green")
    if (wl >= 600 & wl <= 699.99) return("red")
    if (wl >= 700 & wl <= 749.99) return("fr-a")
    if (wl >= 750 & wl <= 799.99) return("fr-b")
    if (wl >= 800 & wl <= 2500) return("nir")
    return(NA)
  }

  # Filter data to only wavelengths within available ranges
supressWarnings({  parsed_colors <- df |>
    dplyr::mutate(
      wavelength = !!wavelength_col,
      color = sapply(wavelength, assign_color),
      value = !!value_col,
      value = dplyr::if_else(value < 0, 0, value)
    ) |>
    dplyr::filter(!is.na(color) & (color %in% available_colors))

  # Check for equally spaced wavelengths
  wavelengths <- parsed_colors$wavelength
  diffs <- base::diff(wavelengths)
  if (any(abs(diffs - mean(diffs, na.rm=TRUE)) > 1e-6)) {
    warning("Wavelength intervals are not equally spaced. Filter or remove wavelength regions with unequal increments")
  }


  # Calculate the total sum of value_col for subsequent fraction calculations
  total_value <- parsed_colors |>
    dplyr::summarise(total = sum(value, na.rm = TRUE)) |>
    dplyr::pull(total)

  # Calculate trapezoidal integral  for improved accuracy
    parsed_colors <- parsed_colors |>
      dplyr::arrange(wavelength) |>
      dplyr::mutate(
        delta_w = ifelse(dplyr::row_number() == 1, NA, wavelength - dplyr::lag(wavelength)),
        trapz_est = ifelse(dplyr::row_number() == 1, NA, delta_w * (value + dplyr::lag(value)) / 2))



  # Define order based on the sequence of ranges
  wavelength_order <- c("uv-c", "uv-b", "uv-a", "blue", "green", "red", "fr-a", "fr-b", "nir")

  # Compute total based on trapz_est
    total_value <- parsed_colors |>
      dplyr::summarise(total = sum(trapz_est, na.rm = TRUE)) |>
      dplyr::pull(total)


  color_fractions <- parsed_colors |>
    dplyr::group_by(color) |>
    dplyr::summarise(
      trapz_sum = round(sum(trapz_est, na.rm = TRUE), 2)) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      percent_of_total = round(100 * (trapz_sum / total_value), 2),
      color = factor(color, levels = wavelength_order)) |>
    dplyr::arrange(color)

  # Return the color fraction summary and transformed dataframe
    return(list(color_fractions = color_fractions |> dplyr::select(-trapz_sum),
                parsed_dataframe = parsed_colors |> dplyr::select(wavelength, trapz_est, color)|>
                  tidyr::drop_na(trapz_est)))})
}

