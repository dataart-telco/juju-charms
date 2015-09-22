#!/bin/bash

WORK_DIR="/var/lib/tads2015-call-consumer"
APP_NAME="tads2015-call-consumer"
APP_PORT=30790
CONFIG_PATH=/etc/default/${APP_NAME}.conf

render_config(){
 
  echo "
EXTERNAL_IP=${EXTERNAL_IP}
REDIS_SERVICE_HOST=${REDIS_SERVICE_HOST}
REDIS_SERVICE_PORT=${REDIS_SERVICE_PORT}
RESTCOMM_SERVICE=${RESTCOMM_SERVICE}
" > ${CONFIG_PATH}
}

render_init(){

    echo '
description "call-consumer"
author "gdubina <gdubina@dataart.com>"
start on runlevel [2345]
stop on runlevel [!2345]
respawn
normal exit 0

limit nofile 20000 20000

script
#  . /etc/default/tads2015-call-consumer.conf
  docker pull tads2015da/demo-main:0.0.9
  exec docker run -d -P --env-file='${CONFIG_FILE}' --name='${APP_NAME}' tads2015da/demo-main:0.0.9 

end script
' > /etc/init/${APP_NAME}.conf

}

setup(){
  docker pull tads2015da/demo-main:0.0.9
  docker create -P --env-file=${CONFIG_FILE} --name=${APP_NAME} tads2015da/demo-main:0.0.9
}

recreate(){
  docker rm ${APP_NAME}
  docker create -P --env-file=${CONFIG_FILE} --name=${APP_NAME} tads2015da/demo-main:0.0.9
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

