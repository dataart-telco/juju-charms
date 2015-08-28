#!/bin/bash
## Description: Configures SIP connectors
## Params:
## 			1. RESTCOMM_HOME
##			2. TELSCALE_ANALYTICS/read-network-props
## Author: Henrique Rosa

# Import network properties
source lib/mobicents/utils/read-network-props.sh

## Description: Configures the connectors for RestComm
## Parameters : 1.Public IP
configConnectors() {
	FILE=/opt/restcomm/standalone/configuration/standalone-sip.xml
	sed -e "s|<connector name=\"sip-udp\" .*/>|<connector name=\"sip-udp\" protocol=\"SIP/2.0\" scheme=\"sip\" socket-binding=\"sip-udp\" use-static-address=\"true\" static-server-address=\"$1\" static-server-port=\"5080\"/>|" \
	    -e "s|<connector name=\"sip-tcp\" .*/>|<connector name=\"sip-tcp\" protocol=\"SIP/2.0\" scheme=\"sip\" socket-binding=\"sip-tcp\" use-static-address=\"true\" static-server-address=\"$1\" static-server-port=\"5080\"/>|" \
	    -e "s|<connector name=\"sip-tls\" .*/>|<connector name=\"sip-tls\" protocol=\"SIP/2.0\" scheme=\"sip\" socket-binding=\"sip-tls\" use-static-address=\"true\" static-server-address=\"$1\" static-server-port=\"5081\"/>|" \
	    -e "s|<connector name=\"sip-ws\" .*/>|<connector name=\"sip-ws\" protocol=\"SIP/2.0\" scheme=\"sip\" socket-binding=\"sip-ws\" use-static-address=\"true\" static-server-address=\"$1\" static-server-port=\"5082\"/>|" \
	    $FILE > $FILE.bak
	mv $FILE.bak $FILE
	juju-log 'Configured SIP Connectors and Bindings'
}

juju-log 'Configuring Application Server...'
configConnectors $PUBLIC_IP
juju-log 'Finished configuring Application Server!'
