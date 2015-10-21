#! /bin/bash

##
## Description: Configures SIP Load Balancer
## Author     : Henrique Rosa
##

##
## DEPENDENCIES
##

RESTCOMM_HOME=/opt/restcomm

##
## FUNCTIONS
##
configLoadBalancer() {
	FILE="$LB_HOME/lb-configuration.properties"
	sed -e "s|^host=.*|host=$PRIVATE_IP|" $FILE > $FILE.bak
	mv $FILE.bak $FILE
	juju-log 'Updated Load Balancer configuration file'
}

configSipStack() {
	FILE="$RESTCOMM_HOME/standalone/configuration/mss-sip-stack.properties"

	juju-log "Will change mss-sip-stack.properties using $1:$2"

		sed -e 's|^#org.mobicents.ha.javax.sip.BALANCERS=|org.mobicents.ha.javax.sip.BALANCERS=|' $FILE > $FILE.bak
		mv $FILE.bak $FILE
		sed -e "s|org.mobicents.ha.javax.sip.BALANCERS=.*|org.mobicents.ha.javax.sip.BALANCERS=$1:$2|" $FILE > $FILE.bak
		mv $FILE.bak $FILE
		juju-log "Activated Load Balancer on SIP stack configuration file with IP Address $1 and port $2"

sed -e '/org.mobicents.ha.javax.sip.BALANCERS=.*/ a\
\org.mobicents.ha.javax.sip.REACHABLE_CHECK=false' \
	    $FILE > $FILE.bak
mv $FILE.bak $FILE

juju-log 'Removed reachable checks and specified HTTP Port 8080'
}

configLogs() {
	# Create directory to keep logs
	mkdir -p $LB_HOME/logs
	juju-log "Created logging directory $LB_HOME/logs"
	
	# make log location absolute
	FILE="$LB_HOME/lb-log4j.xml"
	sed -e "s|<param name=\"file\" value=\".*\"/>|<param name=\"file\" value=\"$LB_HOME/logs/load-balancer.log\"/>|" $FILE > $FILE.bak
	mv -f $FILE.bak $FILE
}

configStandalone() {
	RESTCOMM_HOME=/opt/restcomm
	FILE=$RESTCOMM_HOME/standalone/configuration/standalone-sip.xml
	
	#path_name='org.mobicents.ext'
	#if [ "$RUN_MODE" == "balancer" ]; then
		#path_name="org.mobicents.ha.balancing.only"
	#fi
#	path_name="org.mobicents.ha.balancing.only"	
#	sed -e "s|stack-properties=\"configuration/mss-sip-stack.properties\" path-name=\".*\" |stack-properties=\"configuration/mss-sip-stack.properties\" path-name=\"$path_name\" |" $FILE > $FILE.bak
	
	sed -e "s|path-name=\".*\" \(app-dispatcher-class=.*\)|path-name=\"org.mobicents.ha.balancing.only\" \1|g" $FILE > $FILE.bak
	mv -f $FILE.bak $FILE
	juju-log "changed the MSS Path Setting to org.mobicents.ha.balancing.only" 
}

##
## MAIN
##
#configLogs
#configLoadBalancer
#configSipStack
#configStandalone
