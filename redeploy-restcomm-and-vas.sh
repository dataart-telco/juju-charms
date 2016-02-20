#!/bin/bash

export JUJU_REPOSITORY=$PWD/charms/

if [ "$#" -ge 1 ]; then
    JUJU_CUR_ENV=$1
else
    JUJU_CUR_ENV=`cat ~/.juju/current-environment`
fi

echo 'juju current env: '$JUJU_CUR_ENV

echo 'restcomm:
  voicerss_key: "29b2d893df9f454abbfae94df6cff95b"
  init_password: "42d8aa7cde9c78c4757862d84620c335"
' > /tmp/config-restcomm.yaml

echo 'calls-consumer:
  RESTCOMM_PASSWORD: "42d8aa7cde9c78c4757862d84620c335"
  PHONE_NUMBER: "5555"
  DID_DOMAIN: "81.91.100.135"
' > /tmp/config-calls-consumer.yaml

echo 'conference-call:
  RESTCOMM_PASSWORD: "42d8aa7cde9c78c4757862d84620c335"
  DID_DOMAIN: "81.91.100.135"
' > /tmp/config-conference-call.yaml

echo 'sms-feedback:
  RESTCOMM_PASSWORD: "42d8aa7cde9c78c4757862d84620c335"
  DID_DOMAIN: ""
' > /tmp/config-sms-feedback.yaml

juju remove-service restcomm
juju remove-service calls-consumer
juju remove-service conference-call
juju remove-service sms-feedback

juju deploy local:trusty/restcomm-4mesos-single --config /tmp/config-restcomm.yaml restcomm
juju deploy local:trusty/tads2015-calls-consumer-4mesos --config /tmp/config-calls-consumer.yaml calls-consumer
juju deploy local:trusty/tads2015-conference-call-4mesos --config /tmp/config-conference-call.yaml conference-call
juju deploy local:trusty/tads2015-sms-feedback-4mesos --config /tmp/config-sms-feedback.yaml sms-feedback

juju add-relation restcomm:mysql mysql:db

juju add-relation calls-consumer:restcomm restcomm:website
juju add-relation calls-consumer:redis redis-master:db
juju add-relation calls-consumer:haproxy haproxy:reverseproxy

juju add-relation conference-call:restcomm restcomm:website
juju add-relation conference-call:redis redis-master:db
juju add-relation conference-call:haproxy haproxy:reverseproxy

juju add-relation sms-feedback:restcomm restcomm:website
juju add-relation sms-feedback:redis redis-master:db
juju add-relation sms-feedback:haproxy haproxy:reverseproxy

juju add-relation mesos-master restcomm 
juju add-relation mesos-master calls-consumer
juju add-relation mesos-master conference-call
juju add-relation mesos-master sms-feedback
