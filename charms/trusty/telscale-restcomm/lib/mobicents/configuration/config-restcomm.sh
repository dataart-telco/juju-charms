#!/bin/bash
## Description: Configures RestComm
## Params:
## 			1. RESTCOMM_VERSION
## Author: Henrique Rosa

# IMPORTS
source lib/mobicents/utils/read-network-props.sh
source lib/mobicents/utils/read-user-data.sh

# VARIABLES
RESTCOMM_BIN=/opt/restcomm/bin
RESTCOMM_DARS=/opt/restcomm/standalone/configuration/dars
RESTCOMM_DEPLOY=/opt/restcomm/standalone/deployments/restcomm.war
OUTBOUND_IP='64.136.174.30'

## Description: Configures Java Options for Application Server
## Parameters : none
configJavaOpts() {
	INSTANCE_TYPE=`wget -qO- http://169.254.169.254/latest/meta-data/instance-type`
	FILE=$RESTCOMM_BIN/standalone.conf
	
	RESTCOMM_OPTS=''
	case "$INSTANCE_TYPE" in
		't1.micro')
			RESTCOMM_OPTS='-Xms64m -Xmx256m -XX:+CMSIncrementalPacing -XX:CMSIncrementalDutyCycle=100 -XX:CMSIncrementalDutyCycleMin=100 -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode -XX:MaxPermSize=128m'
			;;
		'm1.small')
			RESTCOMM_OPTS='-Xms512m -Xmx1g -Xmn256m -XX:+CMSIncrementalPacing -XX:CMSIncrementalDutyCycle=100 -XX:CMSIncrementalDutyCycleMin=100 -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode -XX:MaxPermSize=256m'
			;;
		'm1.medium')
			RESTCOMM_OPTS='-Xms2g -Xmx2g -Xmn256m -XX:+CMSIncrementalPacing -XX:CMSIncrementalDutyCycle=100 -XX:CMSIncrementalDutyCycleMin=100 -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode -XX:MaxPermSize=256m'
			;;
		'm1.large')
			RESTCOMM_OPTS='-Xms4g -Xmx4g -Xmn256m -XX:+CMSIncrementalPacing -XX:CMSIncrementalDutyCycle=100 -XX:CMSIncrementalDutyCycleMin=100 -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode -XX:MaxPermSize=256m'
			;;
    esac
	
	if [ -n "$RESTCOMM_OPTS" ]; then
		sed -e "/if \[ \"x\$JAVA_OPTS\" = \"x\" \]; then/ {
			N; s|JAVA_OPTS=.*|JAVA_OPTS=\"$RESTCOMM_OPTS\"|
		}" $FILE > $FILE.bak
		mv $FILE.bak $FILE
		juju-log "Configured JVM for RestComm: $RESTCOMM_OPTS"
	else
		juju-log "Unknown JVM configuration for instance type $INSTANCE_TYPE. Current configuration will be kept."
	fi
}

## Description: Updates RestComm configuration file
## Parameters : 1.Private IP
## 				2.Public IP
configRestcomm() {
	FILE=$RESTCOMM_DEPLOY/WEB-INF/conf/restcomm.xml
	sed -e "s|<local-address>$IP_ADDRESS_PATTERN<\/local-address>|<local-address>$1<\/local-address>|" \
	    -e "s|<remote-address>$IP_ADDRESS_PATTERN<\/remote-address>|<remote-address>$1<\/remote-address>|" \
	    -e "s|<\!--.*<external-ip>.*<\/external-ip>.*-->|<external-ip>$2<\/external-ip>|" \
	    -e "s|<external-ip>.*<\/external-ip>|<external-ip>$2<\/external-ip>|" \
	    -e "s|<external-address>.*<\/external-address>|<external-address>$2<\/external-address>|" \
	    -e "s|<\!--.*<external-address>.*<\/external-address>.*-->|<external-address>$2<\/external-address>|" \
	    -e "s|<prompts-uri>.*<\/prompts-uri>|<prompts-uri>http:\/\/$2:8080\/restcomm\/audio<\/prompts-uri>|" \
	    -e "s|<cache-uri>.*<\/cache-uri>|<cache-uri>http:\/\/$1:8080\/restcomm\/cache<\/cache-uri>|" \
	    -e "s|<recordings-uri>.*<\/recordings-uri>|<recordings-uri>http:\/\/$2:8080\/restcomm\/recordings<\/recordings-uri>|" \
	    -e "s|<error-dictionary-uri>.*<\/error-dictionary-uri>|<error-dictionary-uri>http:\/\/$2:8080\/restcomm\/errors<\/error-dictionary-uri>|" \
	    -e "s|<outbound-proxy-uri>.*<\/outbound-proxy-uri>|<outbound-proxy-uri>$OUTBOUND_IP<\/outbound-proxy-uri>|" \
	    -e "s|<outbound-endpoint>.*<\/outbound-endpoint>|<outbound-endpoint>$OUTBOUND_IP<\/outbound-endpoint>|" \
	    -e 's|<outbound-prefix>.*</outbound-prefix>|<outbound-prefix>#</outbound-prefix>|' $FILE > $FILE.bak;
	mv $FILE.bak $FILE
	juju-log 'Updated RestComm configuration'
}

## Description: Configures Voip Innovations Credentials
## Parameters : 1.Login
## 				2.Password
## 				3.Endpoint
configVoipInnovations() {
	FILE=$RESTCOMM_DEPLOY/WEB-INF/conf/restcomm.xml
	
	sed -e "/<voip-innovations>/ {
		N; s|<login>.*</login>|<login>$1</login>|
        N; s|<password>.*</password>|<password>$2</password>|
        N; s|<endpoint>.*</endpoint>|<endpoint>$3</endpoint>|
	}" $FILE > $FILE.bak
	
	mv $FILE.bak $FILE
	juju-log 'Configured Voip Innovation credentials'
}

## Description: Configures Fax Service Credentials
## Parameters : 1.Username
## 				2.Password
configFaxService() {
	FILE=$RESTCOMM_DEPLOY/WEB-INF/conf/restcomm.xml
	
	sed -e "/<fax-service.*>/ {
		N; s|<user>.*</user>|<user>$1</user>|
		N; s|<password>.*</password>|<password>$2</password>|
	}" $FILE > $FILE.bak
	
	mv $FILE.bak $FILE
	juju-log 'Configured Fax Service credentials'
}

## Description: Configures Speech Recognizer
## Parameters : 1.iSpeech Key
configSpeechRecognizer() {
	FILE=$RESTCOMM_DEPLOY/WEB-INF/conf/restcomm.xml
	
	sed -e "/<speech-recognizer.*>/ {
		N; s|<api-key.*></api-key>|<api-key production=\"true\">$1</api-key>|
	}" $FILE > $FILE.bak
	
	mv $FILE.bak $FILE
	juju-log 'Configured the Speech Recognizer'
}

## Description: Configures available speech synthesizers
## Parameters : none
configSpeechSynthesizers() {
	configAcapela $ACAPELA_APPLICATION $ACAPELA_LOGIN $ACAPELA_PASSWORD
	configVoiceRSS $VOICERSS_KEY
}

## Description: Configures Acapela Speech Synthesizer
## Parameters : 1.Application Code
## 				2.Login
## 				3.Password
configAcapela() {
	FILE=$RESTCOMM_DEPLOY/WEB-INF/conf/restcomm.xml
	
	sed -e "/<speech-synthesizer class=\"org.mobicents.servlet.restcomm.tts.AcapelaSpeechSynthesizer\">/ {
		N
		N; s|<application>.*</application>|<application>$1</application>|
		N; s|<login>.*</login>|<login>$2</login>|
		N; s|<password>.*</password>|<password>$3</password>|
	}" $FILE > $FILE.bak
	
	mv $FILE.bak $FILE
	juju-log 'Configured Acapela Speech Synthesizer'
}

## Description: Configures VoiceRSS Speech Synthesizer
## Parameters : 1.API key
configVoiceRSS() {
	FILE=$RESTCOMM_DEPLOY/WEB-INF/conf/restcomm.xml
	
	sed -e "/<speech-synthesizer class=\"org.mobicents.servlet.restcomm.tts.VoiceRSSSpeechSynthesizer\">/ {
		N
		N; s|<apikey>.*</apikey>|<apikey>$1</apikey>|
	}" $FILE > $FILE.bak
	
	mv $FILE.bak $FILE
	juju-log 'Configured VoiceRSS Speech Synthesizer'
}

## Description: Updates Mobicents properties for RestComm
## Parameters : none
configMobicentsProperties() {
	FILE=$RESTCOMM_DARS/mobicents-dar.properties
	sed -e 's|^ALL=.*|ALL=("RestComm", "DAR\:From", "NEUTRAL", "", "NO_ROUTE", "0")|' $FILE > $FILE.bak
	mv $FILE.bak $FILE
	juju-log "Updated mobicents-dar properties"
}

## Description: Configures restcomm/demos/hello-play.xml demo
## Parameters : 1.Private IP
configPlayDemo() {
	FILE=$RESTCOMM_DEPLOY/demos/hello-play.xml
	sed -e "s|http://$IP_ADDRESS_PATTERN|http://$1|g" $FILE > $FILE.bak
	mv $FILE.bak $FILE
	juju-log 'Configured restcomm/demos/hello-play.xml demo'
}

## Description: Configures restcomm/demos/gather/hello-gather.xml demo
## Parameters : 1.Private IP
configGatherDemo() {
	FILE=$RESTCOMM_DEPLOY/demos/gather/hello-gather.xml
	sed -e "s|http://$IP_ADDRESS_PATTERN|http://$1|g" $FILE > $FILE.bak
	mv $FILE.bak $FILE
	juju-log 'Configured restcomm/demos/gather/hello-gather.xml demo'
}

## Description: Configures restcomm/demos/dial/client/dial-client.xml demo
## Parameters : 1.Private IP
configDialClientDemo() {
	FILE=$RESTCOMM_DEPLOY/demos/dial/client/dial-client.xml
	sed -e "s|http://$IP_ADDRESS_PATTERN|http://$1|g" $FILE > $FILE.bak
	mv $FILE.bak $FILE
	juju-log 'Configured restcomm/demos/dial/client/dial-client.xml demo'
}

## Description: Configures restcomm/demos/dial/conference/dial-conference.xml demo
## Parameters : 1.Private IP
configDialConferenceDemo() {
	FILE=$RESTCOMM_DEPLOY/demos/dial/conference/dial-conference.xml
	sed -e "s|http://$IP_ADDRESS_PATTERN|http://$1|g" $FILE > $FILE.bak
	mv $FILE.bak $FILE
	juju-log 'Configured restcomm/demos/dial/conference/dial-conference.xml demo'
}

configDemos() {
	juju-log 'Configuring RestComm demos...'
	configPlayDemo $PRIVATE_IP
	configGatherDemo $PRIVATE_IP
	configDialClientDemo $PRIVATE_IP
	configDialConferenceDemo $PRIVATE_IP
	juju-log 'Finished configuring RestComm demos!'
}

## Description: Configures Hello-Play demo
## Parameters : 1.IP to bind application to
updateDemoBindings() {
	NUMBERS=( "+1234" "+1235" "+1236" "+1237" "+1238" "+1310" "+1311" )
	
	juju-log 'Updating RestComm demo bindings...'
	for NUMBER in "${NUMBERS[@]}"
	do
		juju-log "	Updating binding of phone number $NUMBER..."
		QUERY_VOICE_URL="SELECT voice_url FROM restcomm.restcomm_incoming_phone_numbers WHERE phone_number=\"$NUMBER\";"
		VOICE_URL=`mysql --password=t3l35taxr00t --execute="$QUERY_VOICE_URL" --skip-column-names --silent`
		VOICE_URL=`juju-log $VOICE_URL | sed -e "s|http://$IP_ADDRESS_PATTERN|http://$1|"`
		
		UPDATE_VOICE_URL="UPDATE restcomm.restcomm_incoming_phone_numbers SET voice_url=\"$VOICE_URL\" WHERE phone_number=\"$NUMBER\";"
		mysql --password=t3l35taxr00t --execute="$UPDATE_VOICE_URL"
		juju-log "	Number $NUMBER is now bound to $VOICE_URL"
	done
	juju-log 'Finished updating RestComm demo bindings!'
}

# MAIN
juju-log 'Configuring RestComm...'
configJavaOpts
configMobicentsProperties
configRestcomm $PRIVATE_IP $PUBLIC_IP
configVoipInnovations $VI_LOGIN $VI_PASSWORD $VI_ENDPOINT
configFaxService $INTERFAX_USER $INTERFAX_PASSWORD
configSpeechRecognizer $ISPEECH_KEY
configSpeechSynthesizers
configDemos
updateDemoBindings $PUBLIC_IP
juju-log 'Configured RestComm!'
