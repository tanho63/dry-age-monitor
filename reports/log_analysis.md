Dry Age Monitor - Log Analysis
================
2026-07-17 12:21:26.398209

``` r
knitr::opts_chunk$set(echo = FALSE, dev = "ragg_png")
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
  library(marquee)
  library(tantastic)
  library(here)
})
here::i_am("reports/log_analysis.Rmd")
```

    ## here() starts at /home/tan/_github/dry-age-monitor

## event timeline

| timestamp           | label                                 |
|:--------------------|:--------------------------------------|
| 2026-07-13 11:00:00 | ribeye added to fridge                |
| 2026-07-14 22:00:00 | initial monitor setup                 |
| 2026-07-15 17:15:00 | usb fan installed vertically          |
| 2026-07-15 23:45:00 | usb fan reinstalled horizontally      |
| 2026-07-16 02:40:00 | add water jug, duct-tape cable-gaps   |
| 2026-07-16 19:20:00 | more jugs, replace fan, use foam tape |
| 2026-07-17 01:15:00 | reorient fan horizontally             |
| 2026-07-17 04:30:00 | slow down fan                         |
| 2026-07-17 16:01:00 | apply +0.5C calibration               |

## Rolling Average Plots

![](log_analysis_files/figure-gfm/plot-1.png)<!-- -->![](log_analysis_files/figure-gfm/plot-2.png)<!-- -->![](log_analysis_files/figure-gfm/plot-3.png)<!-- -->![](log_analysis_files/figure-gfm/plot-4.png)<!-- -->![](log_analysis_files/figure-gfm/plot-5.png)<!-- -->
