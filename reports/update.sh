#! /bin/bash

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

git add reports logs
git commit -m "automated report update $(date)"
git push
