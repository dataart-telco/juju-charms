
[ -f lib/ch-file.sh ] && . lib/ch-file.sh
[ -f lib/utils.sh ] && . lib/utils.sh

update_restcomm_password() {
    local password=$1

}

configure_restcomm() {
    local mediaserver_address=$1
    local mediaserver_port=$2
    local mediaserver_public_address=$3

    # XXX Should all be params taken from outside in changed hook
    local private_host=`unit-get private-address`
    local private_address=`dig +short $private_host`
    local public_host=`unit-get public-address`
    # explicitly use external DNS
    local public_address=`dig +short @8.8.8.8 $public_host`

    source lib/mobicents/configuration/autoconfigure.sh
    #. lib/mobicents/configuration/configuration/autoconfigure.sh
    
    open-port 8080/TCP
    open-port 5080/TCP
    open-port 5082/TCP
    open-port 5080/UDP
    open-port 2000/TCP
    open_media_ports
}

open_media_ports() {
      # XXX: Highly restrict this range so we can only open 10 ports
      # for ec2. This should be a 100 port range
      local lowPort=65434
      local highPort=65535
      
      # FIXME: core doesn't handle port ranges at the time of this writing.
      local portRange=`eval echo {$lowPort..$highPort}`
      for port in $portRange; do
          open-port $port/UDP
      done
}

uninstall_restcomm() {
  rm -Rf /var/lib/tomcat6/webapps/restcomm
  #TODO clean up version dep
  rm -Rf /opt/restcomm
}

