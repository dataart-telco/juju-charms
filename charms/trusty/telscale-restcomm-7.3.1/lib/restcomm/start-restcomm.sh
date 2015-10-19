#! /bin/bash
##
## Description: Starts RestComm with auto-configuration.
##
## Parameters : 1. Bind Address (default: 127.0.0.1)
##              2. Run Mode     [standalone|standalone-lb|domain|domain-lb] (default:standalone)
##
## Author     : Henrique Rosa
##

##
## FUNCTIONS
##

startRestcomm() {
	run_mode="$1"
	bind_address="$2"
	
	# Check if RestComm is already running
	if screen -list | grep -q 'restcomm'; then
		echo 'RestComm is already running on screen session "restcomm", trying to shut it down!'
		source lib/restcomm/stop-restcomm.sh
		#exit 1;
	fi
	
	case $run_mode in
		'standalone'*)
			# start restcomm on standalone mode
			chmod +x $RESTCOMM_HOME/bin/standalone.sh
			screen -dmS 'restcomm' $RESTCOMM_HOME/bin/standalone.sh -b $bind_address -Djboss.bind.address.management=$bind_address
			echo 'RestComm started running on standalone mode. Screen session: restcomm.'
			echo "Using IP Address: $BIND_ADDRESS"
			;;
		'domain'*)
			# start restcomm on standalone mode
			chmod +x $RESTCOMM_HOME/bin/domain.sh
			screen -dmS 'restcomm' $RESTCOMM_HOME/bin/domain.sh -b $bind_address -Djboss.bind.address.management=$bind_address
			echo 'RestComm started running on domain mode. Screen session: restcomm.'
			echo "Using IP Address: $BIND_ADDRESS"
			;;
		*)
			startRestComm 'standalone' $bind_address
			;;
	esac


	if [[ "$run_mode" == *"-lb" ]]; then
		echo 'Starting SIP Load Balancer...'
		if screen -ls | grep -q 'balancer'; then
			echo 'SIP Load Balancer is already running on screen session "balancer"!'
		else
			screen -dmS 'balancer' java -DlogConfigFile=$LB_HOME/lb-log4j.xml \
			-jar $LB_HOME/sip-balancer-jar-with-dependencies.jar \
			-mobicents-balancer-config=$LB_HOME/lb-configuration.properties
			echo 'SIP Load Balancer started running on screen session "balancer"!'
			echo "Using IP Address: $BIND_ADDRESS"
		fi
	fi
}

startMediaServer() {
	echo "Starting Media Server..."
	echo "Media Server will bind to the IP Address: $BIND_ADDRESS"
	if screen -ls | grep -q 'mms'; then
		echo '...Media Server is already running on screen session "mms"!'
	else
		chmod +x $MMS_HOME/bin/run.sh
		screen -dmS 'mms'  $MMS_HOME/bin/run.sh
		echo '...Media Server started running on screen "mms"!'
fi
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

##
## MAIN
##
# GNU screen needs to be installed
if [ -z "$(command -v screen)" ]; then
	echo "ERROR: GNU Screen is not installed! Install it and try again."
	echo "Centos/RHEL: yum install screen"
	echo "Debian/Ubuntu: apt-get install screen"
	exit 1
fi

# ipcalc needs to be installed
if [ -z "$(command -v ipcalc)" ]; then
	echo "ERROR: ipcalc is not installed! Install it and try again."
	echo "Centos/RHEL: yum install ipcalc"
	echo "Debian/Ubuntu: apt-get install ipcalc"
	exit 1
fi

# set environment variables for execution
BASEDIR=/opt/restcomm/bin/restcomm
#BASEDIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
RESTCOMM_HOME=$(cd $BASEDIR/../../ && pwd)
MMS_HOME=$RESTCOMM_HOME/mediaserver
LB_HOME=$RESTCOMM_HOME/tools/sip-balancer
VOICERSS_KEY=`config-get voicerss_key`

echo BASEDIR: $BASEDIR
echo RESTCOMM_HOME: $RESTCOMM_HOME

# input parameters and default values
RUN_MODE='standalone'
NET_INTERFACE='eth0'
PUBLIC_HOSTNAME=`unit-get public-address`
STATIC_ADDRESS=`dig +short @8.8.8.8 $PUBLIC_HOSTNAME`
BIND_ADDRESS=''

while getopts "s:r:i:" optname
do
	case "$optname" in
		"s")
			STATIC_ADDRESS="$OPTARG"
			;;
		"r")
			RUN_MODE="$OPTARG"
			;;
		"i")
			NET_INTERFACE="$OPTARG"
			;;
		":")
			echo "No argument value for option $OPTARG"
			exit 1
			;;
		"?")
			echo "Unknown option $OPTARG"
			exit 1
			;;
		*)
			echo 'Unknown error while processing options'
			exit 1
			;;
	esac
done

# validate network interface and extract network properties
NET_INTERFACES=$(ifconfig | expand | cut -c1-8 | sort | uniq -u | awk -F: '{print $1;}')
if [[ -z $(echo $NET_INTERFACES | sed -n "/$NET_INTERFACE/p") ]]; then
	echo "The network interface $NET_INTERFACE is not available or does not exist."
	echo "The list of available interfaces is: $NET_INTERFACES"
	exit 1
fi

# load network properties for chosen interface
source $BASEDIR/utils/read-network-props.sh "$NET_INTERFACE"
BIND_ADDRESS="$PRIVATE_IP"


# configure restcomm installation
CURRENT_DIR=`pwd`
cd $BASEDIR/autoconfig.d/
rm -f ./*
cd $CHARM_DIR/lib/restcomm/autoconfig.d/
cp -arf ./*  $BASEDIR/autoconfig.d/
cd $CURRENT_DIR

source $BASEDIR/autoconfigure.sh

# start restcomm in selected run mode
startRestcomm "$RUN_MODE" "$BIND_ADDRESS"
startMediaServer
juju-log "Start-Restcomm.sh STATIC ADDRESS: $STATIC_ADRESS"

#open-port 9990/TCP
#open-port 8080/TCP
#open-port 5080/TCP
#open-port 5082/TCP
#open-port 5080/UDP
#open-port 2000/TCP
#open_media_ports
exit 0
