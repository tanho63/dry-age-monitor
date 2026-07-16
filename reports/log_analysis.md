Dry Age Monitor - Log Analysis
================
2026-07-16 07:48:20.938119

``` r
knitr::opts_chunk$set(echo = TRUE, dev = "ragg_png")
suppressPackageStartupMessages({
  library(jsonlite)
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(slider)
  library(lubridate)
  library(glue)
  library(ggplot2)
  library(geomtextpath)
  library(scales)
  library(ragg)
  library(tantastic)
  library(here)
})
here::i_am("reports/log_analysis.Rmd")
```

    ## here() starts at /home/tan/_github/dry-age-monitor

Parameters

``` r
roll_minutes <- 30
timestamp_reference_lines <- tibble::tribble(
  ~timestamp                                        , ~label                             ,
  lubridate::as_datetime("2026-07-13 11:00:00 UTC") , "ribeye added to fridge"           ,
  lubridate::as_datetime("2026-07-14 22:00:00 UTC") , "initial monitor setup"            ,
  lubridate::as_datetime("2026-07-15 17:15:00 UTC") , "usb fan installed vertically"     ,
  lubridate::as_datetime("2026-07-15 23:45:00 UTC") , "usb fan reinstalled horizontally" ,
  lubridate::as_datetime("2026-07-16 02:40:00 UTC") , "add one 4L bottle of water"       ,
  lubridate::as_datetime("2026-07-16 03:40:00 UTC") , "duct-taped cable gaps"            ,
)
```

``` r
.dew_point <- function(temp_c, rh_pct) {
  stopifnot(length(temp_c) == length(rh_pct))
  a <- 17.625
  b <- 243.04

  x <- ((a * temp_c) / (b + temp_c)) + log(rh_pct / 100)

  return((b * x) / (a - x))
}
c_to_f <- function(temp_c) (temp_c * 9/5) + 32
f_to_c <- function(temp_f) (temp_f - 32) * 5/9
```

Pull data via system scp call into the data folder at top level

``` r
system("scp tan@relicanth:/home/tan/dry_age_monitor/logs/* data")
```

``` r
readings <- list.files(path = "data", full.names = TRUE) |>
  purrr::map(readLines) |>
  unlist() |>
  purrr::map(jsonlite::parse_json) |>
  tibble::tibble() |>
  tidyr::unnest_wider(1) |>
  dplyr::mutate(
    timestamp = lubridate::as_datetime(timestamp),
    temperature_f = c_to_f(temperature_c),
    dew_point_f = .dew_point(temperature_c, humidity_pct) |> c_to_f(),
    temp_minus_dewpoint = temperature_f - dew_point_f,
    temp_zone = dplyr::case_when(
      temperature_f >= 40 ~ "danger",
      temperature_f >= 38 ~ "above target",
      dplyr::between(temperature_f, 34, 38) ~ "target",
      temperature_f >= 32 ~ "below target",
      temperature_f < 32 ~ "below freezing"
    ),
    humidity_zone = dplyr::case_when(
      humidity_pct >= 100 ~ "saturation",
      humidity_pct >= 85 ~ "above target",
      humidity_pct >= 75 ~ "target",
      humidity_pct < 75 ~ "below target"
    ),
    dewpoint_zone = dplyr::case_when(
      temp_minus_dewpoint > 0 ~ "ok",
      temp_minus_dewpoint <= 0 ~ "saturation"
    )
  )
```

Rolling Average Plots

``` r
plot_rolling_metric <- function(
  metric_name,
  readings,
  roll_minutes,
  plot_title = NULL,
  plot_subtitle = NULL,
  timestamp_limits = NULL,
  timestamp_reference_lines = NULL,
  metric_units = NULL,
  metric_breaks_width = 1,
  metric_limits = NULL,
  metric_reference_lines = NULL
) {
  plot_pivot <- readings |>
    dplyr::select(
      timestamp,
      dplyr::all_of(metric_name)
    ) |>
    tidyr::pivot_longer(
      -timestamp,
      names_to = "metric",
      values_to = "raw_value"
    ) |>
    dplyr::mutate(
      rollmean = slider::slide_index_dbl(
        .x = raw_value,
        .i = timestamp,
        .f = mean,
        .before = lubridate::minutes(roll_minutes)
      ),
      rollmax = slider::slide_index_dbl(
        .x = raw_value,
        .i = timestamp,
        .f = \(x) quantile(x, 0.95),
        .before = lubridate::minutes(roll_minutes)
      ),
      rollmin = slider::slide_index_dbl(
        .x = raw_value,
        .i = timestamp,
        .f = \(x) quantile(x, 0.05),
        .before = lubridate::minutes(roll_minutes)
      ),
      .by = metric
    ) |>
    tidyr::pivot_longer(
      cols = c("raw_value", "rollmean", "rollmax", "rollmin"),
      names_to = "metric_type",
      values_to = "value"
    )

  plot <- plot_pivot |>
    dplyr::filter(metric_type != "raw_value") |>
    ggplot(aes(x = timestamp)) +
    geom_line(aes(y = value, color = metric_type), size = 1) +
    tantastic::theme_tantastic(
      base_size = 16,
      plot_title_size = 20,
      axis_title_size = 16,
      axis_text_size = 14,
      caption_size = 12
    ) +
    scale_y_continuous(
      limits = metric_limits,
      minor_breaks = scales::minor_breaks_width(metric_breaks_width, 0)
    ) +
    scale_x_datetime(
      limits = timestamp_limits,
      expand = ggplot2::expansion(c(0, 0.1)),
      timezone = "America/Toronto"
    ) +
    labs(
      title = plot_title,
      subtitle = plot_subtitle,
      caption = glue::glue("Rolling metrics over last {roll_minutes} minutes"),
      x = "Timestamp (America/Toronto)",
      y = metric_units
    ) +
    theme(legend.position = "top")

  if (!is.null(metric_reference_lines)) {
    suppressWarnings({
      plot <- plot +
        geom_texthline(
          yintercept = metric_reference_lines$y,
          label = metric_reference_lines$label,
          color = "white",
          hjust = 1,
          data = metric_reference_lines
        )
    })
  }

  if (!is.null(timestamp_reference_lines)) {
    suppressWarnings({
      plot <- plot +
        geom_labelvline(
          xintercept = timestamp_reference_lines$timestamp,
          label = timestamp_reference_lines$label,
          color = "white",
          textcolor = "black",
          alpha = 0.75,
          hjust = 0.5,
          linetype = 2,
          data = timestamp_reference_lines
        )
    })
  }

  return(plot)
}

plot_rolling_metric(
  metric_name = "temperature_f",
  readings = readings,
  roll_minutes = roll_minutes,
  plot_title = "Temperature",
  metric_units = "degrees F",
  metric_limits = c(NA, 48),
  metric_reference_lines = data.frame(
    y = c(32, 34, 38, 40),
    label = c("freezing", "lower", "upper", "danger")
  ),
  timestamp_reference_lines = timestamp_reference_lines
)
```

    ## Warning: Using `size` aesthetic for lines was deprecated in ggplot2 3.4.0.
    ## ℹ Please use `linewidth` instead.
    ## This warning is displayed once per session.
    ## Call `lifecycle::last_lifecycle_warnings()` to see where this warning was generated.

![](log_analysis_files/figure-gfm/plot-1.png)<!-- -->

``` r
plot_rolling_metric(
  metric_name = "humidity_pct",
  readings = readings,
  roll_minutes = roll_minutes,
  plot_title = "Relative Humidity",
  plot_subtitle = "Percentage of theoretical maximum water vapor that can be held in the air at this temperature",
  metric_units = "Percent",
  timestamp_reference_lines = timestamp_reference_lines,
  metric_limits = NULL,
  metric_reference_lines = data.frame(
    y = c(75, 85, 100),
    label = c("lower", "upper", "saturation")
  ),
)
```

![](log_analysis_files/figure-gfm/plot-2.png)<!-- -->

``` r
plot_rolling_metric(
  metric_name = "temp_minus_dewpoint",
  readings = readings,
  roll_minutes = roll_minutes,
  plot_title = "Temp Minus Dewpoint",
  plot_subtitle = "Reaching zero indicates saturation/condensation",
  metric_units = "degrees F",
  timestamp_reference_lines = timestamp_reference_lines,
  metric_limits = NULL,
  metric_reference_lines = data.frame(y = 0, label = "saturation")
)
```

![](log_analysis_files/figure-gfm/plot-3.png)<!-- -->

``` r
plot_rolling_metric(
  metric_name = "pressure_hpa",
  readings = readings,
  roll_minutes = roll_minutes,
  plot_title = "Air Pressure",
  metric_units = "hPa",
  timestamp_limits = NULL,
  timestamp_reference_lines = timestamp_reference_lines,
  metric_breaks_width = 100,
  metric_limits = NULL,
  metric_reference_lines = NULL
)
```

![](log_analysis_files/figure-gfm/plot-4.png)<!-- -->

``` r
plot_rolling_metric(
  metric_name = "gas_ohms",
  readings = readings,
  roll_minutes = roll_minutes,
  plot_title = "Gas Resistance",
  plot_subtitle = "Higher values indicate cleaner air = less offgassing",
  metric_units = "hPa",
  timestamp_limits = NULL,
  timestamp_reference_lines = timestamp_reference_lines,
  metric_limits = NULL,
  metric_breaks_width = 1000,
  metric_reference_lines = NULL
)
```

![](log_analysis_files/figure-gfm/plot-5.png)<!-- -->
