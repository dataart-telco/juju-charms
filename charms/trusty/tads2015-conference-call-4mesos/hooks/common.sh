#!/bin/bash

. ./hooks/marathon_api.sh

WORK_DIR="/var/lib/tads2015-conference-call"
APP_NAME="tads2015-conference-call"
APP_PORT=30791
DOCKER_IMAGE=tads2015da/demo-conference:0.0.9
CPUS=0.3
MEM=400


