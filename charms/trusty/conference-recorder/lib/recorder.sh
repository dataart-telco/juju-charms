#!/bin/bash


socket=/tmp/linphonec-$(id -u)

records_folder=$PWD/records

NUMBER=+5555
USER='bob'
PASS='1234'
PROXY=''

print_usage(){
    printf "usage: [-u user] [-p password] [-h proxy] [-n number] [-d records folder]\n"
}

while getopts 'n:d:u:p:h:' flag; do
    case "${flag}" in
        n)  NUMBER=$OPTARG
            ;;
        u)  USER=$OPTARG
            ;;
        p)  PASS=$OPTARG
            ;;
        h)  PROXY=$OPTARG
            ;;
        d)  records_folder=$OPTARG 
	        ;;
        *)  print_usage
            exit 1
            ;;
    esac
done

if [ -z $PROXY ]; then 
    echo 'Error: Proxy is empty'
    print_usage
    exit 1
fi

filename=$records_folder/record.wav

mkdir -p $records_folder

linphonec --pipe -c /dev/null 2>&1 |
while read -r line
do
    echo $line
    case $line in
        *Ready )
            sleep 1
            echo ">>> initializing"
            for command in "soundcard use files" "register sip:$USER@$PROXY sip:$PROXY $PASS"
            do
                echo -n $command | nc -q 5 -U $socket
            done
            ;;
        *Registration\ on\ *\ successful* )
                echo -n "call $NUMBER" | nc -q 5 -U $socket
            ;;
        *Receiving\ new\ incoming* )           
            echo "!!! New call"
            
            now=$(date +%s)
	    name=record_${now}.wav
            filename=$records_folder/$name
	    echo -n $name > $records_folder/last
	    touch $filename
	    chmod 777 $filename

	    sleep 1
            echo -n "record $filename" | nc -q 5 -U $socket

	    sleep 1	
            echo -n answer | nc -q 5 -U $socket
            ;;
        *Call\ *\ with\ *\ connected. )
            ;;
        *Call*$NUMBER*error*)
            echo "Will call again after 10sec"
            sleep 10
            echo -n "call $NUMBER" | nc -q 5 -U $socket
            ;;
	*Call*DataArt*ended*)
	    echo "Call to conference again..."
	    sleep 10
	    echo -n "call $NUMBER" | nc -q 5 -U $socket
            ;;
        *Terminating* )
            echo "Finish script"
            sleep 3
            #echo -n quit | nc -q 5 -U $socket
            #sleep 2
            #exit 1
            
            # force close app
	    pid=`ps -ax | grep "linphonec --pipe" | head -1 | sed 's/ *//' | cut -d" " -f1`            
            kill -9 $pid
            ;;
        *)
            #echo ">>> $line"
            ;;
    esac
done
