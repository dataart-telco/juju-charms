#!/bin/bash
APP_NAME=conference-recorder
APP_PORT=8080

WORK_DIR=/var/lib/$APP_NAME
CONFIG_PATH=${WORK_DIR}/${APP_NAME}.conf


install(){
  rm -rf $WORK_DIR
  mkdir -p $WORK_DIR

  #install jujuapicli
  apt-get install -y linphone

  #install server
  cp ./lib/recorder.sh $WORK_DIR/${APP_NAME}.sh

  render_config
  render_init

  open-port $APP_PORT
}

render_config(){
  echo "
USER=${USER}
PASSWORD=${PASSWORD}
PROXY=${PROXY}
NUMBER=${NUMBER}
" > $CONFIG_PATH
}

render_init(){

    echo '
description "conference-recorder"
author "gdubina <gdubina@dataart.com>"
start on runlevel [2345]
stop on runlevel [!2345]
respawn
normal exit 0

limit nofile 20000 20000

script
  . '$CONFIG_PATH'
  '$WORK_DIR'/'$APP_NAME'.sh -u '$USER' -p '$PASSWORD' -h '$PROXY' -n '$NUMBER' -d '$WORK_DIR'/records
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
