#! /bin/bash
## Description: Starts RestComm and Media Server on separate GNU Screen sessions
## Parameters : none
## Authors    : Henrique Rosa   henrique.rosa@telestax.com   

# Guarantee RestComm configuration is up-to-date
#source /etc/profile
#source $RESTCOMM_ADMIN/config/autoconfigure.sh

# Import network properties
source lib/mobicents/utils/read-network-props.sh

# Start MariaDB if needed
#service mysql status | grep -i 'success' || service mysql start 

export RESTCOMM_VERSION=7.1.3.GA
export RESTCOMM_HOME=/opt/restcomm
export MMS_HOME=$RESTCOMM_HOME/telscale-media/telscale-media-server

# Start Media Server with GNU Screen
juju-log "Starting TelScale Media Server..."
if screen -ls | grep -q 'mms'; then
	juju-log 'TelScale Media Server is already running on screen session "mms"!'
else
	chmod +x $MMS_HOME/bin/run.sh
	screen -dmS 'mms'  $MMS_HOME/bin/run.sh
	juju-log 'TelScale Media Server started running on screen "mms"!'
fi

# Start Media Server with GNU Screen
juju-log "Starting RestComm $RESTCOMM_VERSION..."
if screen -list | grep -q 'restcomm'; then
	juju-log 'TelScale RestComm is already running on screen session "restcomm"!'
else
	chmod +x $RESTCOMM_HOME/bin/standalone.sh
	screen -dmS 'restcomm' $RESTCOMM_HOME/bin/standalone.sh -b $PRIVATE_IP -bmanagement $PRIVATE_IP
	juju-log 'TelScale RestComm started running on screen session "restcomm"!'
fi

if [ "$RUN_MODE" == "balancer" ]; then
	juju-log 'Starting SIP Load Balancer...'
	if screen -ls | grep -q 'balancer'; then
		juju-log 'SIP Load Balancer is already running on screen session "balancer"!'
	else
		screen -dmS 'balancer' java -DlogConfigFile=$LB_HOME/lb-log4j.xml \
		-jar $LB_HOME/sip-balancer-jar-with-dependencies.jar \
		-mobicents-balancer-config=$LB_HOME/lb-configuration.properties
		juju-log 'SIP Load Balancer started running on screen session "balancer"!'
	fi
fi
