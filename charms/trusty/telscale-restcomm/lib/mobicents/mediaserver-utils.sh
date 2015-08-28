[ -f lib/ch-file.sh ] && . lib/ch-file.sh
[ -f lib/utils.sh ] && . lib/utils.sh

download_mediaserver() {
  cd /opt
  if [ ! -e restcomm-saas-tomcat-1.0.0.CR2-SNAPSHOT.zip ]; then
      wget -q https://mobicents.ci.cloudbees.com/job/RestComm/lastSuccessfulBuild/artifact/restcomm-saas-tomcat-1.0.0.CR2-SNAPSHOT.zip
  fi
  unzip restcomm-saas-tomcat-1.0.0.CR2-SNAPSHOT.zip
  mv restcomm-saas-tomcat-1.0.0.CR2-SNAPSHOT mediaserver
  cd $CHARM_DIR
}

install_mediaserver_upstart() {
  local mediaserver_root=$1
  local java_args="" #"-Xms512m -Xmx1g -Xmn256m -XX:+CMSIncrementalPacing -XX:CMSIncrementalDutyCycle=100 -XX:CMSIncrementalDutyCycleMin=100 -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode -XX:MaxPermSize=256m"
  local mediaserver_args=""
  cd $CHARM_DIR
  ch_template_file 0644 \
                   root:root \
                   templates/mediacenter-defaults \
                   /etc/default/mediaserver \
                   "java_args mediaserver_root mediaserver_args"
  install --mode=644 --owner=root --group=root $CHARM_DIR/files/mediaserver.conf /etc/init/
}

install_mediaserver() {
  local jar_file=/opt/restcomm/telscale-media/telscale-media-server
  install_mediaserver_upstart "/opt/mediaserver" $jar_file
}

configure_server() {
    local bind_address=$1
    local bind_network=$2
    local bind_subnet=$3
    local lowPort=$4
    local highPort=$5
    
    
    
}

configure_ports() {
      # XXX: Highly restrict this range so we can only open 10 ports
      # for ec2. This should be a 1k port range
      local lowPort=$1
      local highPort=$2

      open-port 2427/TCP
      # XXX: core doesn't handle port ranges at the time of this writing.
      # XXX: do with a manual rule in ec2 console for now
      #local portRange=`eval echo {$lowPort..$highPort}`
      #for port in $portRange; do
      #    open-port $port/UDP
      #done
}

configure_logging() {
    local config=/opt/mediaserver/mobicents-media-server/conf/log4j.xml
    local context=`tempfile`

    attr param name File value /opt/mediaserver/logs/mediaserver.log >> $context
    ./lib/xml-template.py -n $config $context
    rm $context
}

configure_mediaserver() {
    local bind_address=$1
    local bind_network=$2
    local bind_subnet=$3
    local lowPort=64534
    local highPort=65534
    configure_server $bind_address $bind_network $bind_subnet $lowPort $highPort
    configure_ports $lowPort $highPort
    configure_logging

}

restart_mediaserver() {
  service mediaserver status && service mediaserver restart || :
}

stop_mediaserver() {
  if [ -e /etc/init/mediaserver.conf ]; then
      service mediaserver stop || :
  fi
}

uninstall_mediaserver() {
  rm -f /etc/init/mediaserver.conf
  rm -f /etc/default/mediaserver
  rm -Rf /opt/mediaserver
}


