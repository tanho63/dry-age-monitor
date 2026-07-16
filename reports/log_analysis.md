Dry Age Monitor - Log Analysis
================
2026-07-16 17:41:07.260509

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

Parameters

``` r
roll_minutes <- 30
start_date <- lubridate::as_datetime("2026-07-13 12:00:00 UTC")
end_date <- Sys.time()
timestamp_reference_lines <- tibble::tribble(
  ~timestamp                                        , ~label                                  ,
  lubridate::as_datetime("2026-07-13 11:00:00 UTC") , "ribeye added to fridge"                ,
  lubridate::as_datetime("2026-07-14 22:00:00 UTC") , "initial monitor setup"                 ,
  lubridate::as_datetime("2026-07-15 17:15:00 UTC") , "usb fan installed vertically"          ,
  lubridate::as_datetime("2026-07-15 23:45:00 UTC") , "usb fan reinstalled horizontally"      ,
  lubridate::as_datetime("2026-07-16 02:40:00 UTC") , "add water jug, duct-tape cable-gaps"   ,
  lubridate::as_datetime("2026-07-16 19:20:00 UTC") , "more jugs, replace fan, use foam tape" ,
)
```

Pull data via system scp call into the data folder at top level

Rolling Average Plots

    ## Warning: Using `size` aesthetic for lines was deprecated in ggplot2 3.4.0.
    ## ℹ Please use `linewidth` instead.
    ## This warning is displayed once per session.
    ## Call `lifecycle::last_lifecycle_warnings()` to see where this warning was generated.

![](log_analysis_files/figure-gfm/plot-1.png)<!-- -->![](log_analysis_files/figure-gfm/plot-2.png)<!-- -->![](log_analysis_files/figure-gfm/plot-3.png)<!-- -->![](log_analysis_files/figure-gfm/plot-4.png)<!-- -->![](log_analysis_files/figure-gfm/plot-5.png)<!-- -->
