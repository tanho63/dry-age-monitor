#! /bin/bash
set -euxo pipefail
while true
do
    rclone copyto --s3-no-head -v /home/tan/dry-age-monitor/logs sunlake-r2:sunlake/dry-age-monitor/logs
    # sleep for five minutes
    sleep 300
done;
