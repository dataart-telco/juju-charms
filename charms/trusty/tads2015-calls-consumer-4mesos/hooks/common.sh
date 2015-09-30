#!/bin/bash

. ./hooks/marathon_api.sh

WORK_DIR="/var/lib/tads2015-calls-consumer"
APP_NAME="tads2015-calls-consumer"
APP_PORT=30790
DOCKER_IMAGE=tads2015da/demo-main:0.0.9
CPUS=0.3
MEM=400


