#! /bin/bash

set -euxo pipefail
rclone copyto /home/tan/dry-age-monitor/logs sunlake-r2:sunlake/dry-age-monitor/logs --s3-no-head

