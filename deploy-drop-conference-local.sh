export JUJU_REPOSITORY=$PWD/charms/

juju set-env "default-series=trusty"
juju set-constraints "mem=512M"
#juju set-constraints 'instance-type=m1.small'

juju deploy local:trusty/tads2015-drop-conference-4mesos drop-conference
juju add-relation drop-conference:redis redis-master:db
juju add-relation drop-conference:restcomm restcomm:website
juju add-relation drop-conference mesos-master
