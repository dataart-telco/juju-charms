#! /bin/bash

##
## Description: Configures JBoss AS
## Author     : Henrique Rosa
##

disableSplashScreen() {
	FILE="/opt/restcomm/standalone/configuration/standalone-sip.xml"
	sed -e 's|enable-welcome-root=".*"|enable-welcome-root="false"|' $FILE > $FILE.bak
	mv -f $FILE.bak $FILE
	juju-log '...disabled JBoss splash screen...'
}

juju-log 'Configuring JBoss AS...'
disableSplashScreen
juju-log 'Finished configuring JBoss AS!'
