#! /bin/bash

# cron automated report. this is configured to run on my other home server rather
# than on the pi: it takes too long to run rmarkdown render with only 500mb memory

IMAGE=da-report:latest
DIR="/home/tan/dry-age-monitor"
set -euxo pipefail

# sync data from S3 to local dir for report
rclone sync sunlake-r2:sunlake/dry-age-monitor/logs $DIR/logs --s3-no-head

cd $DIR
git pull
docker run \
  --rm \
  -v "$DIR":/dry-age-monitor \
  --entrypoint R \
  "$IMAGE" \
  -e "rmarkdown::render('/dry-age-monitor/reports/da-01/da-01.Rmd', output_format = 'html_document')"

rclone copyto $DIR/reports/da-01/da-01.html sunlake-r2:sunlake/dry-age-monitor/da-01.html --s3-no-head
