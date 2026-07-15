readings <- list.files(path = "logs",full.names = TRUE) |>
  purrr::map(readLines) |>
  unlist() |>
  purrr::map(jsonlite::parse_json) |>
  tibble::tibble() |>
  tidyr::unnest_wider(1) |>
  dplyr::mutate(
    timestamp = lubridate::as_datetime(timestamp),
    temp_rolling = slider::slide_dbl(temperature_c, mean, .before = 60),
    humidity_rolling = slider::slide_dbl(humidity_pct, mean, .before = 60)
  )

readings |>
  ggplot2::ggplot(ggplot2::aes(x = timestamp)) +
  ggplot2::geom_point(ggplot2::aes(y = temp_rolling)) +
  tantastic::theme_tantastic(base_size = 16, plot_title_size = 20) +
  ggplot2::scale_y_continuous(limits = c(0, NA)) +
  ggplot2::scale_x_datetime(timezone = "America/Toronto") +
  ggplot2::labs(
    title = "Temperature",
    subtitle = "Rolling mean of last 30 minutes",
    x = "Timestamp (America/Toronto)",
    y = "°C"
  )

readings |>
  ggplot2::ggplot(ggplot2::aes(x = timestamp)) +
  ggplot2::geom_point(ggplot2::aes(y = humidity_rolling)) +
  tantastic::theme_tantastic(base_size = 16, plot_title_size = 20) +
  ggplot2::scale_y_continuous(limits = c(20, 100)) +
  ggplot2::scale_x_datetime(timezone = "America/Toronto") +
  ggplot2::labs(
    title = "Humidity",
    subtitle = "Rolling mean of last 30 minutes",
    x = "Timestamp (America/Toronto)",
    y = "%"
  )
