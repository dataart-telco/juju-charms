#!/bin/bash
APP_NAME=simple-monitor-agent

WORK_DIR=/var/lib/$APP_NAME
CONFIG_PATH=${WORK_DIR}/agent.conf

install(){
  rm -rf $WORK_DIR
  mkdir -p $WORK_DIR
  
  cp ./lib/monitor-agent $WORK_DIR/$APP_NAME

  render_config
  render_juju_tool_config
  render_init
}

render_config(){
  echo "
SERVER_HOST=${SERVER_HOST}
JUJU_SERVICE_ID=${JUJU_SERVICE_ID}
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
  '$WORK_DIR'/'$APP_NAME' -url $SERVER_HOST -appId $JUJU_SERVICE_ID
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

