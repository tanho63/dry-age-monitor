#! /bin/bash

# cron automated report. this is configured to run on my other home server rather
# than on the pi: it takes too long to run rmarkdown render with only 500mb memory

IMAGE=damr:latest
DIR="/home/tan/dry-age-monitor"
set -euxo pipefail

cd $DIR
rclone sync relicanth:$DIR/logs $DIR/logs

git pull
docker run \
  --rm \
  -v "$DIR":/dry-age-monitor \
  --entrypoint R \
  "$IMAGE" \
  -e "rmarkdown::render('/dry-age-monitor/reports/log_analysis.Rmd', output_format = 'all')"

rclone copyto $DIR/reports/log_analysis.html sunlake-r2:sunlake/dry-age-monitor.html

git add logs
git commit -m "logs update $(date)"
git push
