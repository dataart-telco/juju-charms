#!/bin/bash

# parent script should define the following VARS
# WORK_DIR="/var/lib/tads2015-conference-call"
# APP_NAME="tads2015-conference-call"
# APP_PORT=30791
# DOCKER_IMAGE=tads2015da/demo-conference:0.0.9
# CPUS
# MEM

CONFIG_PATH=${WORK_DIR}/${APP_NAME}.conf
FILE_CREATE=$WORK_DIR/create.json

APP_MANAGER_API=http://127.0.0.1:8080/v2/apps

install(){
  mkdir -p ${WORK_DIR}

  EXTERNAL_IP=`unit-get private-address`
  REDIS_SERVICE_HOST='127.0.0.1'
  REDIS_SERVICE_PORT='6379'
  RESTCOMM_SERVICE='127.0.0.1'

  render_config
  setup

  open-port $APP_PORT
}

render_config(){
 
  echo "
EXTERNAL_IP=${EXTERNAL_IP}
REDIS_SERVICE_HOST=${REDIS_SERVICE_HOST}
REDIS_SERVICE_PORT=${REDIS_SERVICE_PORT}
RESTCOMM_SERVICE=${RESTCOMM_SERVICE}
" > ${CONFIG_PATH}

  render_create
}

render_create(){
  echo '{
  "id": "'$APP_NAME'", 
  "cpus": '$CPUS',
  "mem": '$MEM',
  "instances": 0,
  "container": {
    "type": "DOCKER",
    "docker": {
      "network": "BRIDGE",
      "image": "'$DOCKER_IMAGE'",
      "parameters": [
        { "key": "env", "value": "EXTERNAL_IP='$EXTERNAL_IP'" },
        { "key": "env", "value": "REDIS_SERVICE_HOST='$REDIS_SERVICE_HOST'" },
        { "key": "env", "value": "REDIS_SERVICE_PORT='$REDIS_SERVICE_PORT'" },
        { "key": "env", "value": "RESTCOMM_SERVICE='$RESTCOMM_SERVICE'" }
      ],
      "portMappings": [
        { "containerPort": '$APP_PORT', "hostPort": 0, "servicePort": '$APP_PORT', "protocol": "tcp" }
      ]
    }
  }
}' > $FILE_CREATE
}

api_create(){
  juju-log 'API_CREATE'

  curl -H "Content-Type: application/json" -X POST -d @$FILE_CREATE $APP_MANAGER_API
}

api_delete(){
  juju-log 'API_DELETE'

  curl -H "Content-Type: application/json" -X DELETE $APP_MANAGER_API/$APP_NAME?force=true
}

api_suspend(){
  juju-log 'API_SUSPEND'

  api_instances 0
}

api_instances(){
  juju-log "API_INSTANCES: $1"

  curl -H "Content-Type: application/json" -X PUT -d '{"instances":'$1'}' $APP_MANAGER_API/$APP_NAME?force=true
}

start_me(){
  juju-log 'START_ME'

  api_instances 1
}

stop_me(){
  juju-log 'STOP_ME'

  api_instances 0 
}

restart_me(){
  juju-log 'RESTART_ME'

  api_delete
  api_create
  
  start_me
}

