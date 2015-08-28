#! /bin/bash
## Description: Executes all RestComm configuration scripts (config*.sh)
##              for a given version.
## Author: Henrique Rosa

juju-log 'RestComm automatic configuration started:'

for f in lib/mobicents/configuration/config*.sh; do
	juju-log "Executing configuration file $f..."
	source $f
	juju-log "Finished executing configuration file $f!"
done
juju-log 'RestComm automatic configuration finished!'
