export JUJU_REPOSITORY=$PWD/charms/

JUJU_ENV=$1

juju set-env -e $JUJU_ENV "default-series=trusty"
#juju set-constraints "mem=512M"
#juju set-constraints 'instance-type=m1.small'

echo 'sms-feedback:
  RESTCOMM_PASSWORD: "42d8aa7cde9c78c4757862d84620c335"
  DID_DOMAIN: ""
' > /tmp/config-sms-feedback.yaml


juju deploy -e $JUJU_ENV local:trusty/tads2015-sms-feedback-4mesos sms-feedback --config /tmp/config-sms-feedback.yaml

juju add-relation -e $JUJU_ENV sms-feedback:redis redis-master:db
juju add-relation -e $JUJU_ENV sms-feedback:restcomm restcomm:website
juju add-relation -e $JUJU_ENV haproxy:reverseproxy sms-feedback:haproxy
juju add-relation -e $JUJU_ENV sms-feedback mesos-master
juju add-relation -e $JUJU_ENV sms-feedback:recorder conference-recorder:api
