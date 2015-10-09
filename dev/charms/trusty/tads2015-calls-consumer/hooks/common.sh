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
  . /etc/default/tads2015-call-consumer.conf
  cd '$WORK_DIR'
  exec ./demo-main-server -host=$EXTERNAL_IP -redis=$REDIS_SERVICE_HOST:$REDIS_SERVICE_PORT -restcomm=$RESTCOMM_SERVICE
end script
' > /etc/init/${APP_NAME}.conf

}

restart_me(){
   stop $APP_NAME
   start $APP_NAME
}

