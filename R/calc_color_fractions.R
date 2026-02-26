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
#' parsed_dataframe <- color_summary$parsed_colors
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
    "uv-c" = seq(200, 279.9999, by = 0.0001),
    "uv-b" = seq(280, 314.9999, by = 0.0001),
    "uv-a" = seq(315, 399.9999, by = 0.0001),
    "blue" = seq(400, 499.9999, by = 0.0001),
    "green" = seq(500, 599.9999, by = 0.0001),
    "red" = seq(600, 699.9999, by = 0.0001),
    "fr-a" = seq(700, 749.9999, by = 0.0001),
    "fr-b" = seq(750, 799.9999, by = 0.0001),
    "nir" = seq(800, 2500, by = 0.0001)
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
    available_colors <- setdiff(available_colors, exclude_colors)
  }

  # Find missing ranges
  missing_colors <- setdiff(names(ranges), available_colors)

  # Warn only if missing ranges are not all excluded
  if (length(missing_colors) > 0 &&
      (is.null(exclude_colors) || !all(missing_colors %in% exclude_colors))) {
    warning("Missing wavelength ranges for: ", paste(missing_colors, collapse = ", "))
  }


  # Assign color based on wavelength, only if range exists
  assign_color <- function(wl) {
    if (wl >= 200 & wl <= 279.9999) return("uv-c")
    if (wl >= 280 & wl <= 314.9999) return("uv-b")
    if (wl >= 315 & wl <= 399.9999) return("uv-a")
    if (wl >= 400 & wl <= 499.9999) return("blue")
    if (wl >= 500 & wl <= 599.9999) return("green")
    if (wl >= 600 & wl <= 699.9999) return("red")
    if (wl >= 700 & wl <= 749.9999) return("fr-a")
    if (wl >= 750 & wl <= 799.9999) return("fr-b")
    if (wl >= 800 & wl <= 2500) return("nir")
    return(NA)
  }

  # Filter data to only wavelengths within available ranges
  parsed_colors <- df |>
    dplyr::mutate(
      wavelength = !!wavelength_col,
      color = sapply(wavelength, assign_color),
      value = !!value_col,
      value = dplyr::if_else(value < 0, 0, value)
    ) |>
    dplyr::filter(!is.na(color) & (color %in% available_colors))


  # Calculate the total sum of value_col for subsequent fraction calculations
  total_value <- parsed_colors |>
    dplyr::summarise(total = sum(value, na.rm = TRUE)) |>
    dplyr::pull(total)

  # Calculate trapezoidal integral  for improved accuracy
    parsed_colors <- parsed_colors |>
      dplyr::arrange(wavelength) |>
      dplyr::mutate(
        y = value,
        x = wavelength,
        # 2. Calculate the 'heights' (y) and 'widths' (dx)
        # We use lead() to look at the next point to form the trapezoid
        y_next = dplyr::lead(y),
        dx = dplyr::lead(x) - x,
        # 3. Trapezoid area formula: ((y1 + y2) / 2) * dx
        trapz_est = ((y + y_next) / 2) * dx) |>
      # Remove the last row which will be NA because lead() has no successor
      tidyr::drop_na(trapz_est) |>
      dplyr::select(-y, -y_next, -x, -dx)

  # Define order based on the sequence of ranges
  wavelength_order <- c("uv-c", "uv-b", "uv-a", "blue", "green", "red", "fr-a", "fr-b", "nir")

  # Compute total based on trapz_est
    total_value <- parsed_colors |>
      dplyr::summarise(total = sum(trapz_est, na.rm = TRUE)) |>
      dplyr::pull(total)


  color_fractions <- parsed_colors |>
    dplyr::group_by(color) |>
    dplyr::summarise(
      trapz_sum = sum(trapz_est, na.rm = TRUE)) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      percent_of_total = round(100 * (trapz_sum / total_value), 2),
      color = factor(color, levels = wavelength_order)) |>
    dplyr::arrange(color)

  # Return the color fraction summary and transformed dataframe
    return(list(color_fractions = color_fractions |> dplyr::select(-trapz_sum),
                parsed_dataframe = parsed_colors |> dplyr::select(wavelength, trapz_est, color)|>
                  tidyr::drop_na(trapz_est)))
}

