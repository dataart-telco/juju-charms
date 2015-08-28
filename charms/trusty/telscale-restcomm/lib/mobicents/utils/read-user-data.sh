#!/bin/bash
# This file pulls the user configuration from Amazon and updates
# the TelScale RestComm configuration file.
# 
# When the user is prompted he/she should enter the user data
# in the Amazon console in the following format:
#
# vi_login=alice
# vi_password=bob
# vi_endpoint=123456
# interfax_user=alice
# ...
#
# Please see below for a list of variables. If you need more details about the
# meaning of these variables please find that information in the restcomm.xml
# file.
#
# Author: Henrique Rosa

## Description: Gets user data by key. Note that the keys are case insensitive.
## Parameters : 1.Key that points to the user data entry
readUserData() {
	curl -f -s http://169.254.169.254/latest/user-data | grep -i "$1" | awk -F= '{print $2}'
}

# VoIP Innovations variable declarations
VI_LOGIN=$(readUserData vi_login)
VI_PASSWORD=$(readUserData vi_password)
VI_ENDPOINT=$(readUserData vi_endpoint)

# Interfax variable declarations.
INTERFAX_USER=$(readUserData interfax_user)
INTERFAX_PASSWORD=$(readUserData interfax_password)

# ISpeech variable declarations.
ISPEECH_KEY=$(readUserData ispeech_key)

# Acapela variable declarations.
ACAPELA_APPLICATION=$(readUserData acapela_application)
ACAPELA_LOGIN=$(readUserData acapela_login)
ACAPELA_PASSWORD=$(readUserData acapela_password)

# VoiceRSS variable declarations
VOICERSS_KEY=$(readUserData voicerss_key)

# Run Mode: RestComm Standalone (default), Load Balancer
RUN_MODE=$(readUserData run_mode)
if [ "$RUN_MODE" != "balancer" ]; then
	RUN_MODE='standalone'
fi