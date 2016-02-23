#!/bin/bash

export JUJU_REPOSITORY=$PWD/charms/
echo 'restcomm:
  voicerss_key: "29b2d893df9f454abbfae94df6cff95b"
  init_password: "42d8aa7cde9c78c4757862d84620c335"
' > /tmp/config-restcomm.yaml

juju deploy local:trusty/restcomm-4mesos-single --config /tmp/config-restcomm.yaml restcomm
juju add-relation restcomm:mysql mysql:db

juju add-relation calls-consumer:restcomm restcomm:website
juju add-relation conference-call:restcomm restcomm:website
juju add-relation sms-feedback:restcomm restcomm:website
juju add-relation mailagent:restcomm restcomm:website
juju add-relation drop-conference:restcomm restcomm:website

juju add-relation mesos-master restcomm 
