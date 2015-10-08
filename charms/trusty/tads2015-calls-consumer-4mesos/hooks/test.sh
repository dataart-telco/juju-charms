#!/bin/bash

. common.sh

SERVICES='services=['
SERVICES+="{'service_name': '${APP_NAME}_${APP_PORT}',"
SERVICES+=" 'service_host': '0.0.0.0',"
SERVICES+=" 'service_port': '${APP_PORT}',"
SERVICES+=" 'service_options': ['mode http', 'balance roundrobin', 'option forwardfor'"
SERVICES+="],"
SERVICES+=" 'servers': ["

tasks=`until curl -sSfLk -m 10 -H 'Accept: text/plain' http://192.168.176.220:8080/v2/apps/$APP_NAME/tasks; do [ $# -lt 2 ] && return 1 || shift; done`

while read -r txt 
do
    echo $txt
    set -- $txt
    if [ $# -lt 2 ]; then
        shift $#
        continue
    fi
    shift 2

    while [[ $# -ne 0 ]]
    do
        server=$1
        server_name=`echo $server | sed 's/:.*//g'`
        server_port=`echo $server | sed 's/.*://g'`

        echo $server
        echo $server_name
        echo $server_port 

        SERVICES+="['${APP_NAME}_$#', '$server_name', '$server_port', 'check'],"
        
        shift
    done
done <<< $tasks

SERVICES+="]}"
SERVICES+="]"

echo $SERVICES
