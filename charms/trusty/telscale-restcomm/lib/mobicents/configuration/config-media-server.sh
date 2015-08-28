#!/bin/bash
## Description: Configures the Media Server
## Params:
## 			1. RESTCOMM_VERSION
## Author: Henrique Rosa

# Import network properties
source lib/mobicents/utils/read-network-props.sh
MMS_HOME=/opt/restcomm/telscale-media/telscale-media-server

## Description: Updates UDP Manager configuration
## Parameters : 1. Private IP
## 				2. Local Network
## 				3. Local Subnet
configUdpManager() {
	FILE=$MMS_HOME/deploy/server-beans.xml
		
	sed -e "s|<property name=\"bindAddress\">$IP_ADDRESS_PATTERN<\/property>|<property name=\"bindAddress\">$1<\/property>|" \
	    -e "s|<property name=\"localBindAddress\">$IP_ADDRESS_PATTERN<\/property>|<property name=\"localBindAddress\">$1<\/property>|" \
	    -e "s|<property name=\"localNetwork\">$IP_ADDRESS_PATTERN<\/property>|<property name=\"localNetwork\">$2<\/property>|" \
	    -e "s|<property name=\"localSubnet\">$IP_ADDRESS_PATTERN<\/property>|<property name=\"localSubnet\">$3<\/property>|" \
	    -e 's|<property name="useSbc">.*</property>|<property name="useSbc">true</property>|' \
	    -e 's|<property name="dtmfDetectorDbi">.*</property>|<property name="dtmfDetectorDbi">36</property>|' \
	    -e 's|<response-timeout>.*</response-timeout>|<response-timeout>5000</response-timeout>|' \
	    -e 's|<property name="lowestPort">.*</property>|<property name="lowestPort">65434</property>|' \
	    -e 's|<property name="highestPort">.*</property>|<property name="highestPort">65535</property>|' \
	    $FILE > $FILE.bak
	    
	grep -q -e '<property name="lowestPort">.*</property>' $FILE.bak || sed -i '/rtpTimeout/ a\
    <property name="lowestPort">65434</property>' $FILE.bak
    
    grep -q -e '<property name="highestPort">.*</property>' $FILE.bak || sed -i '/rtpTimeout/ a\
    <property name="highestPort">65535</property>' $FILE.bak
	
	mv $FILE.bak $FILE
	juju-log 'Configured UDP Manager'
}

## Description: Updates Java Options for Media Server
## Parameters : none
configJavaOpts() {
    INSTANCE_TYPE=`wget -qO- http://169.254.169.254/latest/meta-data/instance-type`
    FILE=$MMS_HOME/bin/run.sh
    
	MMS_OPTS=''
	case "$INSTANCE_TYPE" in
		't1.micro')
			MMS_OPTS='$JAVA_OPTS -Xms64m -Xmx128m -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000'
			;;
		'm1.small')
			MMS_OPTS='$JAVA_OPTS -Xms128m -Xmx256m -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000'
			;;
		'm1.medium')
			MMS_OPTS='$JAVA_OPTS -Xms1g -Xmx1g -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000'
			;;
		'm1.large')
			MMS_OPTS='$JAVA_OPTS -Xms2g -Xmx2g -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000'
			;;
    esac
    
    if [ -n "$MMS_OPTS" ]; then
    	sed -e "/# Setup MMS specific properties/ {
    		N; s|JAVA_OPTS=.*|JAVA_OPTS=\"$MMS_OPTS\"|
		}" $FILE > $FILE.bak
		mv $FILE.bak $FILE
		juju-log "Updated Java Options for Media Server: $MMS_OPTS"
    else
    	juju-log "Unknown JVM configuration for instance type $INSTANCE_TYPE. Current configuration will be kept."
    fi
}

configLogDirectory() {
	FILE=$MMS_HOME/conf/log4j.xml
	DIRECTORY=$MMS_HOME/log
	
	sed -e "/<param name=\"File\" value=\".*server.log\" \/>/ s|value=\".*server.log\"|value=\"$DIRECTORY/server.log\"|" $FILE > $FILE.bak
	mv $FILE.bak $FILE
	juju-log 'Updated log configuration'
}

juju-log 'Configuring Mobicents Media Server...'
configUdpManager $PRIVATE_IP $NETWORK $SUBNET_MASK
configJavaOpts
configLogDirectory
juju-log 'Finished configuring Mobicents Media Server!'
