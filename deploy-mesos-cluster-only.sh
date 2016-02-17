#!/bin/bash

export JUJU_REPOSITORY=$PWD/charms/

if [ "$#" -ge 1 ]; then
    JUJU_CUR_ENV=$1
else
    JUJU_CUR_ENV=`cat ~/.juju/current-environment`
fi

echo 'juju current env: '$JUJU_CUR_ENV

juju set-env -e $JUJU_CUR_ENV "default-series=trusty"
juju set-constraints "mem=512M"

juju deploy --constraints="mem=4G cpu-cores=2" local:trusty/mesos-master
juju deploy --constraints="mem=4G cpu-cores=2" local:trusty/mesos-slave
juju deploy --constraints="mem=1.5G" cs:trusty/mysql-33
juju deploy local:trusty/restcomm-4mesos restcomm

juju add-relation restcomm mesos-master

juju add-relation mesos-master mesos-slave
