#!/bin/bash
APP_NAME=conference-recorder
APP_PORT=8080

WORK_DIR=/opt/$APP_NAME
CONFIG_PATH=${WORK_DIR}/${APP_NAME}.conf

install(){
  rm -rf $WORK_DIR
  mkdir -p -m 777 $WORK_DIR

  #install jujuapicli
  apt-get install -y linux-image-extra-virtual
  modprobe snd-dummy

  apt-get install -y linphone
  apt-get install -y nginx

  init_nginx

  #install server
  cp ./lib/recorder.sh $WORK_DIR/${APP_NAME}.sh

  render_config
  render_init

  open-port $APP_PORT

  open-port 5060
 
  open-port 5061
  open-port 9000-9500/UDP

  open-port 2000/TCP
  open-port 2000/UDP
  open-port 5065/TCP
  open-port 5065/UDP

  open-port 2427/TCP

  open-port 65434-65535/UDP
 
  open-port 5080/TCP
  open-port 5080/UDP

  open-port 5082/TCP
  open-port 9990/TCP

}

render_config(){
  echo "
USER=${USER}
PASSWORD=${PASSWORD}
PROXY=${PROXY}
NUMBER=${NUMBER}
" > $CONFIG_PATH
}

init_nginx(){
  echo "
server {
        listen 8080;
        root $WORK_DIR/records;
        location /{
        }
}
" > /etc/nginx/sites-available/recorder

ln -s /etc/nginx/sites-available/recorder /etc/nginx/sites-enabled/recorder

service nginx restart
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
  sudo -u ubuntu '$WORK_DIR'/'$APP_NAME'.sh -u $USER -p $PASSWORD -h $PROXY -n $NUMBER -d '$WORK_DIR'/records

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
