#!/bin/bash
APP_NAME=simple-monitor-server

WORK_DIR=/var/lib/$APP_NAME
CONFIG_PATH=${WORK_DIR}/${APP_NAME}.conf
JUJU_TOOL_CONFIG_PATH=${WORK_DIR}/.jujuapi.yaml

install(){
  rm -rf $WORK_DIR
  mkdir -p $WORK_DIR

  #install jujuapicli
  apt-get install -y python-jujuclient
  cp ./lib/jujuapicli $WORK_DIR

  #install server
  cp ./lib/monitor-server $WORK_DIR/$APP_NAME

  render_config
  render_init
}

render_juju_tool_config(){

  echo "juju-api:
  endpoint: "wss://"${JUJU_API_HOST}"/ws"
  admin-secret: ${JUJU_API_PASSWORD}
" > $JUJU_TOOL_CONFIG_PATH

}

render_config(){
  echo "
REDIS_HOST=${REDIS_HOST}
CHECK_PERIOD=${CHECK_PERIOD}
PORT=${PORT}
JUJU_API_HOST=${JUJU_API_HOST}
JUJU_API_PASSWORD=${JUJU_API_PASSWORD}
JUJU_DEPLOY_DELAY=${JUJU_DEPLOY_DELAY}
MESOS_DEPLOY_DELAY=${MESOS_DEPLOY_DELAY}
MARATHON_API_HOST=${MARATHON_API_HOST}
SCALE_UP=${SCALE_UP}
SCALE_DOWN=${SCALE_DOWN}
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
  '$WORK_DIR'/'$APP_NAME' -r $REDIS_HOST -p $PORT -t $CHECK_PERIOD -jd $JUJU_DEPLOY_DELAY -md $MESOS_DEPLOY_DELAY -up $SCALE_UP -down $SCALE_DOWN -m $MARATHON_API_HOST -cli-dir '$WORK_DIR'
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
