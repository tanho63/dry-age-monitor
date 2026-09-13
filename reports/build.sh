#! /bin/bash

# build da-report docker image

IMAGE=da-report
docker build -t "$IMAGE" reports
