#!/bin/bash

export JUJU_REPOSITORY=$PWD/charms/

echo 'calls-consumer:
  RESTCOMM_PASSWORD: "42d8aa7cde9c78c4757862d84620c335"
  PHONE_NUMBER: "5555"
  DID_DOMAIN: "81.91.100.135"
' > /tmp/config-calls-consumer.yaml

juju deploy local:trusty/tads2015-calls-consumer-4mesos --config /tmp/config-calls-consumer.yaml calls-consumer

juju add-relation calls-consumer:restcomm restcomm:website
juju add-relation calls-consumer:redis redis-master:db
juju add-relation calls-consumer:haproxy haproxy:reverseproxy
juju add-relation mesos-master calls-consumer

