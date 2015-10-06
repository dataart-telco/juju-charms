#!/bin/bash
APP_NAME=monitor-agent-docker

WORK_DIR=/var/lib/$APP_NAME
CONFIG_PATH=${WORK_DIR}/${APP_NAME}.conf

install(){
  rm -rf $WORK_DIR
  mkdir -p $WORK_DIR
  
  cp ./lib/monitor-agent-docker $WORK_DIR/$APP_NAME

  render_config
  render_init
}

render_config(){
  echo "
SERVER_HOST=${SERVER_HOST}
JUJU_SERVICE_ID=${JUJU_SERVICE_ID}
UPDATE_PERIOD=${UPDATE_PERIOD}
" > $CONFIG_PATH
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
  . '$CONFIG_PATH'
  '$WORK_DIR'/'$APP_NAME' -url $SERVER_HOST -t $UPDATE_PERIOD
end script
' > /etc/init/${APP_NAME}.conf

}

start_me(){
  if [ -z "`status $APP_NAME | grep start`" ]; then
    start $APP_NAME
  fi
}

stop_me(){
  if [ -n "`status $APP_NAME | grep start`" ]; then
    stop $APP_NAME
  fi
}

restart_me(){
  stop_me
  start_me
#  restart $APP_NAME
}

