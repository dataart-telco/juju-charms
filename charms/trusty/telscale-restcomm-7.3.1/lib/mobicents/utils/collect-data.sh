#!/bin/bash
##
## Description : Collects system data, traces and logs.
## Dependencies: 1.read-network-props.sh
## 				 2.Environment Variables: JAVA_HOME
## Authors     : Henrique Rosa (henrique.rosa@telestax.com)
## 				 George Vagenas (gvagenas@telestax.com)
##
source $TELSCALE_ANALYTICS/read-network-props.sh

##
## VARIABLES
##
BASE_DIR=$TELSCALE_ANALYTICS/log
AUTOMATIC="false"
JMAP="false"

##
## PARAMETER VALIDATION
##
if [ -z "$JAVA_HOME" ]; then
	echo "JAVA_HOME is not defined. Please setup this environment variable and try again."
	exit 1
fi

# parse the flag options (and their arguments)
while getopts "ahm" OPT; do
	case "$OPT" in
		h)
			echo "Description: Collects system data. The output is a compressed file."
			echo " "
			echo "collect-data [options]"
			echo " "
			echo "options:"
			echo "-m collect jmap"
			echo "-a automatic invokation"
			echo "-h show brief help"
			exit 0
			;;
		m)
        	JMAP="true"
        	;;
        a)
			AUTOMATIC="true"
			;;
		?)
        	echo "Invalid option: $OPTARG"
        	echo "Type \"collect-data -help\" for instructions"
        	exit 1 ;;
    esac
done

# get rid of the just-finished flag arguments
shift $(($OPTIND-1))

##
## FUNCTIONS
##
getPID(){
	MMS_PID=`lsof -i:2427 | awk '{ print $2 }' | grep -o '[0-9]\{2,\}'`
	MSS_PID=`lsof -i:2727 | awk '{ print $2 }' | grep -o '[0-9]\{2,\}'`
}

silent_copy() {
	[ -f $1 ] && cp $1 $2
}

collect_mss_logs() {
	FROM=$RESTCOMM_HOME/standalone/log
	TO=$SAVE_DIR/sip-servlets
	
	mkdir -p $TO
	silent_copy $FROM/boot.log* $TO
	silent_copy $FROM/server.log* $TO
	silent_copy $FROM/mss-jsip-messages.xml $TO
	silent_copy $FROM/mss-jsip-debuglog.txt $TO
	echo 'Collected Sip Servlets Logs'
}

collect_mms_logs() {
	FROM=$MMS_HOME/log
	TO=$SAVE_DIR/media-server
	
	mkdir -p $TO
	silent_copy $FROM/server.log* $TO
	silent_copy $FROM/scheduler.log* $TO
	echo 'Collected Media Server Logs'
}

collect_lb_logs() {
	FROM=$LB_HOME/logs
	TO=$SAVE_DIR/load-balancer
	
	mkdir -p $TO
	silent_copy $FROM/load-balancer.log* $TO
	echo 'Collected SIP Load Balancer Logs'
}

collect_ps_info() {
	ps -e -o %cpu,%mem,stime,user,pid,cmd > $SAVE_DIR/system/ps-info
	echo 'Taken snapshot of the current processes'
}

collect_netstat_info() {
	netstat -anp > $SAVE_DIR/system/netstat-info
	echo 'Collected network status'
}

collect_mem_info() {
	free -m > $SAVE_DIR/system/mem-info
	echo 'Collected memory usage information'
}

collect_messages(){
	silent_copy /var/log/messages $SAVE_DIR/system
	echo 'Collected general system activity messages'
}

mms_jstack(){
	$JAVA_HOME/bin/jstack -l $MMS_PID > $SAVE_DIR/trace/mms-jstack-$DATE
	echo 'Collected Media Server stack traces'
}

mss_jstack(){
	$JAVA_HOME/bin/jstack -l $MSS_PID > $SAVE_DIR/trace/mss-jstack-$DATE
	echo 'Collected Sip Servlets stack traces'
}

mms_jmap(){
	$JAVA_HOME/bin/jmap -heap:format=b $MMS_PID 
	mv heap.bin $SAVE_DIR/trace/mms-heap-$DATE.bin
	echo 'Collected Media Server object memory maps'
}

mss_jmap(){
	$JAVA_HOME/bin/jmap -heap:format=b $MSS_PID
	mv heap.bin $SAVE_DIR/trace/mss-heap-$DATE.bin
	echo 'Collected Sip Servlets object memory maps'
}

tar_file() {
	echo 'Compressing collected data folder...'
	cd $SAVE_DIR
	tar -pczf $SAVE_DIR.tar.gz *
	cd $(dirname $0)
	if [ "$AUTOMATIC" == "true" ]; then
		chown root:root $SAVE_DIR.tar.gz
	else
		chown customer:customer $SAVE_DIR.tar.gz
	fi
	echo 'Data folder compressed!'
	rm -rf $SAVE_DIR
	echo 'Deleted data folder'
}

##
## MAIN
##
DATE=`date +%b_%d_%Y-%H_%M`
SAVE_DIR="$BASE_DIR/manual/$DATE"
if [ "$AUTOMATIC" == "true" ]; then
	SAVE_DIR="$BASE_DIR/system/$DATE"
fi

echo "Collecting logs and traces..."
[ "$JMAP" == "true" ] && echo "...JMAP files will be also collected..."

mkdir -p $SAVE_DIR/{media-server,sip-servlets,system,trace}

ENV_FILE=$SAVE_DIR/environment-info
echo "Date     : $DATE" > $ENV_FILE
echo "Local-IP : $PRIVATE_IP" >> $ENV_FILE
echo "Public-IP: $PUBLIC_IP" >> $ENV_FILE

collect_mss_logs
collect_mms_logs
collect_lb_logs
collect_ps_info
collect_netstat_info
collect_mem_info
collect_messages
getPID
mms_jstack
mss_jstack

if [ "$JMAP" == "true" ]; then
	mms_jmap
	mss_jmap
fi

tar_file
echo 'Finished collecting data!'