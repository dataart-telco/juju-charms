#!/bin/bash

ELASTIC_APP_ID='eipalloc-ba3efbd3'

INSTANCE_ID=`aws ec2 describe-instances --filter "Name=instance-state-code,Values=16" "Name=tag-value,Values=telscale-restcomm/0" | grep "InstanceId" | sed "s|.*: ||" | cut -d '"' -f2`

if [ -z "$INSTANCE_ID" ]; then
	echo "Instance id is emapty"
	exit 1
else
	echo "Bind static address to $INSTANCE_ID" 

	aws ec2 associate-address --instance-id $INSTANCE_ID --allocation-id $ELASTIC_APP_ID
fi
