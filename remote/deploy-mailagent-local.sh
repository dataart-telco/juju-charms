JUJU_ENV=$1

export JUJU_REPOSITORY=$PWD/../charms/

juju set-env -e $JUJU_ENV  "default-series=trusty"
#juju set-constraints "mem=512M"
#juju set-constraints 'instance-type=m1.small'

juju deploy -e $JUJU_ENV local:trusty/tads2015-mailagent-4mesos mailagent --config config-mailagent.yaml
juju add-relation -e $JUJU_ENV mailagent:redis redis-master:db
juju add-relation -e $JUJU_ENV mailagent mesos-master
