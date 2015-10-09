#!/bin/bash

SERVICE_NAME="main"
APP_NAME="tads2015-call-consumer"
APP_PORT=30790
TMPL_DIR=$APP_NAME/tmpl
CONFIG_PATH=${CHARM_DIR}/${APP_NAME}.conf

clone_repo(){
  rm -rf vas-demo-docker-repo
  git clone https://github.com/taddemo2015/vas-demo-docker-repo

  rm -rf $TMPL_DIR
  mkdir -p $TMPL_DIR

  cp vas-demo-docker-repo/kube-yml/prod2/* $TMPL_DIR
}


render_config(){

  echo "
EXTERNAL_IP=${EXTERNAL_IP}
REDIS_SERVICE_HOST=${REDIS_SERVICE_HOST}
REDIS_SERVICE_PORT=${REDIS_SERVICE_PORT}
RESTCOMM_SERVICE=${RESTCOMM_SERVICE}
" > $CONFIG_PATH
}

render_init(){

  cp $TMPL_DIR/${SERVICE_NAME}-service.yml ${APP_NAME}/${SERVICE_NAME}-service.yml

  sed "s/EXTERNAL_IP_VALUE/"$EXTERNAL_IP"/g" ${TMPL_DIR}/${SERVICE_NAME}-controller.yml > ${APP_NAME}/${SERVICE_NAME}-controller.yml
  sed -i "s/RESTCOMM_SERVICE_VALUE/"${RESTCOMM_SERVICE}"/g" ${APP_NAME}/${SERVICE_NAME}-controller.yml
  sed -i "s/REDIS_SERVICE_HOST_VALUE/"${REDIS_SERVICE_HOST}"/g" ${APP_NAME}/${SERVICE_NAME}-controller.yml
  sed -i "s/REDIS_SERVICE_PORT_VALUE/"${REDIS_SERVICE_PORT}"/g" ${APP_NAME}/${SERVICE_NAME}-controller.yml

}

restart_me(){
  echo "Restart me: stop controller and create again"

  export KUBERNETES_MASTER=`netstat -nap | grep apiserver | grep LISTEN | grep 8080 | awk '{print $4}'`

  kubectl stop -f ${CHARM_DIR}/${APP_NAME}/${SERVICE_NAME}-controller.yml 
  kubectl create -f ${CHARM_DIR}/${APP_NAME}/${SERVICE_NAME}-controller.yml

}

kubectl_create(){
  echo "try to create service, rc, pods"
  echo "charm dir: "${CHARM_DIR}

  export KUBERNETES_MASTER=`netstat -nap | grep apiserver | grep LISTEN | grep 8080 | awk '{print $4}'`

  kubectl create -f ${CHARM_DIR}/${APP_NAME}/${SERVICE_NAME}-service.yml
  kubectl create -f ${CHARM_DIR}/${APP_NAME}/${SERVICE_NAME}-controller.yml
}

kubectl_stop(){
  echo "try to stop service, rc, pods"
  
  export KUBERNETES_MASTER=`netstat -nap | grep apiserver | grep LISTEN | grep 8080 | awk '{print $4}'`

  kubectl stop -f ${CHARM_DIR}/${APP_NAME}/${SERVICE_NAME}-service.yml
  kubectl stop -f ${CHARM_DIR}/${APP_NAME}/${SERVICE_NAME}-controller.yml
}

kubectl_recreate(){
  echo "recreate rc and pods"

  export KUBERNETES_MASTER=`netstat -nap | grep apiserver | grep LISTEN | grep 8080 | awk '{print $4}'`

  kubectl stop -f ${CHARM_DIR}/${APP_NAME}/${SERVICE_NAME}-controller.yml
  kubectl create -f ${CHARM_DIR}/${APP_NAME}/${SERVICE_NAME}-controller.yml
}
