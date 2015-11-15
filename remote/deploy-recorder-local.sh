JUJU_ENV=$1

export JUJU_REPOSITORY=$PWD/../charms/

juju set-env -e $JUJU_ENV "default-series=trusty"

echo 'conference-recorder:
  user: "recorder"
  password: "1234"
  proxy: "52.28.141.175:5080"
  number: "5555"
' > /tmp/conference-recorder.yaml

juju deploy -e $JUJU_ENV local:trusty/conference-recorder conference-recorder --config /tmp/conference-recorder.yaml
juju add-relation -e $JUJU_ENV sms-feedback:recorder conference-recorder:api
juju expose -e $JUJU_ENV conference-recorder
 
