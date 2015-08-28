#! /bin/bash
## Description: Stops RestComm and Media Server processes running on GNU Screen sessions
## Parameters : none
## Authors    : Henrique Rosa   henrique.rosa@telestax.com   

source /etc/profile
#source $TELSCALE_ANALYTICS/read-user-data.sh

if [ "$RUN_MODE" == "balancer" ]; then
	juju-log 'Stopping SIP Load Balancer...'
	if screen -ls | grep -q 'balancer'; then
		screen -S 'balancer' -p 0 -X 'quit'
		juju-log 'Stopped SIP Load Balancer running on screen session "balancer"!'
	else
		juju-log 'SIP Load Balancer already stopped!'
	fi
fi

# Stop Media Server with GNU Screen
juju-log "Stopping TelScale Media Server..."
if screen -ls | grep -q 'mms'; then
	screen -S 'mms' -p 0 -X 'quit'
	juju-log 'Stopped TelScale Media Server instance running on screen session "mms"!'
else
	juju-log 'TelScale Media Server already stopped!'
fi

# Stop RestComm with GNU Screen
juju-log "Stopping RestComm..."
if screen -list | grep -q 'restcomm'; then
	screen -S 'restcomm' -p 0 -X 'quit'
	juju-log 'Stopped RestComm instance running on screen session "restcomm"!'
else
	juju-log 'TelScale RestComm already stopped!'
fi
