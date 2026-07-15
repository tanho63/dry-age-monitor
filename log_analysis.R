roll_minutes <- 30
readings <- list.files(path = "logs",full.names = TRUE) |>
  purrr::map(readLines) |>
  unlist() |>
  purrr::map(jsonlite::parse_json) |>
  tibble::tibble() |>
  tidyr::unnest_wider(1) |>
  dplyr::mutate(
    timestamp = lubridate::as_datetime(timestamp),
    temperature_f = (temperature_c * 9/5) + 32,
    temp_rolling = slider::slide_dbl(temperature_f, mean, .before = 2 * roll_minutes),
    humidity_rolling = slider::slide_dbl(humidity_pct, mean, .before = 2 * roll_minutes)
  )

readings |>
  ggplot2::ggplot(ggplot2::aes(x = timestamp)) +
  ggplot2::geom_point(ggplot2::aes(y = temp_rolling)) +
  tantastic::theme_tantastic(base_size = 16, plot_title_size = 20) +
  ggplot2::scale_y_continuous(
    limits = c(32, NA),
    breaks = seq.int(32, max(readings$temp_rolling))
  ) +
  ggplot2::scale_x_datetime(timezone = "America/Toronto") +
  ggplot2::labs(
    title = "Temperature",
    subtitle = glue::glue("Rolling mean of last {roll_minutes} minutes"),
    x = "Timestamp (America/Toronto)",
    y = "°F"
  )

readings |>
  ggplot2::ggplot(ggplot2::aes(x = timestamp)) +
  ggplot2::geom_point(ggplot2::aes(y = humidity_rolling)) +
  tantastic::theme_tantastic(base_size = 16, plot_title_size = 20) +
  ggplot2::scale_y_continuous(limits = c(20, 100)) +
  ggplot2::scale_x_datetime(timezone = "America/Toronto") +
  ggplot2::labs(
    title = "Humidity",
    subtitle = glue::glue("Rolling mean of last {roll_minutes} minutes"),
    x = "Timestamp (America/Toronto)",
    y = "%"
  )
