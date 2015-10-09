#!/bin/bash
WORK_DIR=/var/lib/zabbix-jujucli
CONFIG_PATH=${WORK_DIR}/.jujuapi.yaml

install(){
  rm -rf $WORK_DIR
  mkdir -p $WORK_DIR
  
  apt-get install python-jujuclient
  
  cp ./lib/jujuapicli $WORK_DIR

  render_config
}


render_config(){

  echo "juju-api:
  endpoint: "wss://"${JUJU_API_HOST}"/ws"
  admin-secret: ${JUJU_API_PASSWORD} 
" > $CONFIG_PATH
}


