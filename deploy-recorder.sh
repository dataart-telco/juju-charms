export JUJU_REPOSITORY=$PWD/charms/

JUJU_ENV=$1

juju set-env -e $JUJU_ENV "default-series=trusty"
#juju set-constraints "mem=512M"
#juju set-constraints 'instance-type=m1.small'

echo 'conference-recorder:
  user: "bob"
  password: "1234"
  proxy: "52.28.141.175:5080"
  number: "+5555"
' > /tmp/conference-recorder.yaml

juju deploy -e $JUJU_ENV local:trusty/conference-recorder conference-recorder --config /tmp/conference-recorder.yaml
juju expose -e $JUJU_ENV conference-recorder
 
