export JUJU_REPOSITORY=$PWD/charms/

juju set-env "default-series=trusty"
juju set-constraints "mem=512M"
#juju set-constraints 'instance-type=m1.small'

juju deploy local:trusty/tads2015-mailagent-4mesos mailagent --config config-mailagent.yaml
juju add-relation mailagent:redis redis-master:db
juju add-relation mailagent mesos-master
