export JUJU_REPOSITORY=$PWD/charms/

juju set-env "default-series=trusty"
juju set-constraints "mem=512M"
#juju set-constraints 'instance-type=m1.small'

juju deploy local:trusty/telscale-restcomm --config config-restcomm.yaml

juju add-relation calls-consumer:restcomm telscale-restcomm:website
juju add-relation conference-call:restcomm telscale-restcomm:website
juju add-relation sms-feedback:restcomm telscale-restcomm:website

juju expose telscale-restcomm
