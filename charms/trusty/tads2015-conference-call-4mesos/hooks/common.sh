#!/bin/bash

WORK_DIR="/var/lib/tads2015-conference-call"
APP_NAME="tads2015-conference-call"
APP_PORT=30791
DOCKER_IMAGE=tads2015da/conference-call:0.0.10
CPUS=0.5
MEM=200

CONFIG_PATH=${WORK_DIR}/${APP_NAME}.conf
FILE_CREATE=$WORK_DIR/create.json

CRON_CMD_FILE=$WORK_DIR/update_ha_service.sh
CRON_JOB='* * * * * /bin/bash '$CRON_CMD_FILE' >> /var/log/'$APP_NAME'_cron.log 2>&1'

APP_MANAGER_API=http://127.0.0.1:8080/v2/apps

install(){
  mkdir -p ${WORK_DIR}

  EXTERNAL_IP=`unit-get private-address`
  REDIS_SERVICE_HOST='127.0.0.1'
  REDIS_SERVICE_PORT='6379'
  RESTCOMM_SERVICE='127.0.0.1'
  UNIT_NAME=$JUJU_UNIT_NAME

  render_config

  render_cron_file

  open-port $APP_PORT
}

render_cron_file(){
    echo "
. ${CHARM_DIR}/hooks/common.sh
. $CONFIG_PATH

run_update_haproxy
    " > $CRON_CMD_FILE
    
    chmod +x $CRON_CMD_FILE
}
render_config(){
 
  echo "
EXTERNAL_IP=${EXTERNAL_IP}
REDIS_SERVICE_HOST=${REDIS_SERVICE_HOST}
REDIS_SERVICE_PORT=${REDIS_SERVICE_PORT}
RESTCOMM_SERVICE=${RESTCOMM_SERVICE}
UNIT_NAME=${UNIT_NAME}
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
        { "key": "env", "value": "RESTCOMM_SERVICE='$RESTCOMM_SERVICE'" },
        { "key": "env", "value": "COLLECTD_DOCKER_APP='$APP_NAME'" },
        { "key": "env", "value": "COLLECTD_DOCKER_TASK_ENV=MESOS_TASK_ID" }
      ],
      "portMappings": [
        { "containerPort": '$APP_PORT', "hostPort": 0, "servicePort": 0, "protocol": "tcp" }
      ]
    }
  },
  "labels": {
        "collectd_docker_app": "'$APP_NAME'",
        "collectd_docker_task": "'$APP_NAME'"
  }
}' > $FILE_CREATE
}

get_ha_service(){
    SERVICES='services=['
    SERVICES+="{'service_name': '${APP_NAME}_${APP_PORT}',"
    SERVICES+=" 'service_host': '0.0.0.0',"
    SERVICES+=" 'service_port': '${APP_PORT}',"
    SERVICES+=" 'service_options': ['mode http', 'balance roundrobin', 'option forwardfor'"
    SERVICES+="],"
    SERVICES+=" 'servers': ["

    tasks=`curl -sSfLk -m 10 -H 'Accept: text/plain' $APP_MANAGER_API/$APP_NAME/tasks?force=true`

    while read -r txt
    do
        set -- $txt
        if [ $# -lt 2 ]; then
            shift $#
            continue
        fi
        shift 2

        while [[ $# -ne 0 ]]
        do
            server=$1
            server_name=`echo $server | sed 's/:.*//g'`
            server_port=`echo $server | sed 's/.*://g'`

            SERVICES+="['${APP_NAME}_$#', '$server_name', '$server_port', 'check'],"

            shift
        done
    done <<< $tasks

    SERVICES+="]}"
    SERVICES+="]"

    echo $SERVICES
}

api_create(){
  juju-log 'API_CREATE'

  curl -H "Content-Type: application/json" -X POST -d @$FILE_CREATE $APP_MANAGER_API?force=true
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
  cron_add
}

stop_me(){
  juju-log 'STOP_ME'

  api_instances 0 
  cron_remove
}

restart_me(){
  juju-log 'RESTART_ME'

  api_delete
  api_create
  
  start_me
}

run_update_haproxy(){
    juju-run $UNIT_NAME actions/mesos-app-changed
}
cron_add(){
    ( crontab -l | grep -v "$CRON_CMD_FILE" ; echo "$CRON_JOB" ) | crontab -
}

cron_remove(){
    ( crontab -l | grep -v "$CRON_CMD_FILE" ) | crontab -
}
