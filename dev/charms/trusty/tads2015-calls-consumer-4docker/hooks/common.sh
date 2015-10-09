#!/bin/bash

WORK_DIR="/var/lib/tads2015-call-consumer"
APP_NAME="tads2015-call-consumer"
APP_PORT=30790
CONFIG_PATH=/etc/default/${APP_NAME}.conf
DOCKER_IMAGE=tads2015da/demo-main:0.0.9

render_config(){
 
  echo "
EXTERNAL_IP=${EXTERNAL_IP}
REDIS_SERVICE_HOST=${REDIS_SERVICE_HOST}
REDIS_SERVICE_PORT=${REDIS_SERVICE_PORT}
RESTCOMM_SERVICE=${RESTCOMM_SERVICE}
" > ${CONFIG_PATH}
}

setup(){
  docker pull $DOCKER_IMAGE
  docker create -p ${APP_PORT}:${APP_PORT} --env-file=${CONFIG_PATH} --name=${APP_NAME} $DOCKER_IMAGE
}

recreate(){
  docker rm ${APP_NAME}
  docker create -p ${APP_PORT}:${APP_PORT} --env-file=${CONFIG_PATH} --name=${APP_NAME} $DOCKER_IMAGE
}

start_me(){
  docker start ${APP_NAME}
}

stop_me(){
  docker stop ${APP_NAME} 
}

restart_me(){
  stop_me
  recreate
  start_me
}

