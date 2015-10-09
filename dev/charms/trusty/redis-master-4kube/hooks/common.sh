#!/bin/bash
SERVICE="redis"
APP_NAME="redis-master"
APP_PORT=6379
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
" > $CONFIG_PATH
}

render_init(){

  cp $TMPL_DIR/${SERVICE}-service.yml ${APP_NAME}/${SERVICE}-service.yml
  cp $TMPL_DIR/${SERVICE}-controller.yml ${APP_NAME}/${SERVICE}-controller.yml

}

get_service_cluster_ip(){
  export KUBERNETES_MASTER=`netstat -nap | grep apiserver | grep LISTEN | grep 8080 | awk '{print $4}'`
  
  echo `kubectl get services $1 -o template --template='{{.spec.clusterIP}}'`
}

update_external_ip(){
 . $CONFIG_PATH
  EXTERNAL_IP=`get_service_cluster_ip $SERVICE`
  render_config
  notify_redis_master_relation
}

notify_redis_master_relation(){
  RELATION_ID=`relation-ids db`

  MY_PORT="6379"

  . ${CONFIG_PATH}

  if [ -n "$RELATION_ID" ]; then
    relation-set -r $RELATION_ID hostname="${EXTERNAL_IP}" port="${MY_PORT}"
  fi

}

restart_me(){
  echo "Restart me: stop controller and create again"

  export KUBERNETES_MASTER=`netstat -nap | grep apiserver | grep LISTEN | grep 8080 | awk '{print $4}'`

  kubectl stop -f ${CHARM_DIR}/${APP_NAME}/${SERVICE}-controller.yml 
  kubectl create -f ${CHARM_DIR}/${APP_NAME}/${SERVICE}-controller.yml
}

kubectl_create(){
  echo "try to create service, rc, pods"
  echo "charm dir: "${CHARM_DIR}

  export KUBERNETES_MASTER=`netstat -nap | grep apiserver | grep LISTEN | grep 8080 | awk '{print $4}'`

  kubectl create -f ${CHARM_DIR}/${APP_NAME}/${SERVICE}-service.yml
  kubectl create -f ${CHARM_DIR}/${APP_NAME}/${SERVICE}-controller.yml

  update_external_ip
}

kubectl_stop(){
  echo "try to stop service, rc, pods"
  
  export KUBERNETES_MASTER=`netstat -nap | grep apiserver | grep LISTEN | grep 8080 | awk '{print $4}'`

  kubectl stop -f ${CHARM_DIR}/${APP_NAME}/${SERVICE}-service.yml
  kubectl stop -f ${CHARM_DIR}/${APP_NAME}/${SERVICE}-controller.yml
}

kubectl_recreate(){
  echo "recreate rc and pods"

  export KUBERNETES_MASTER=`netstat -nap | grep apiserver | grep LISTEN | grep 8080 | awk '{print $4}'`

  kubectl stop -f ${CHARM_DIR}/${APP_NAME}/${SERVICE}-controller.yml
  kubectl create -f ${CHARM_DIR}/${APP_NAME}/${SERVICE}-controller.yml
}
