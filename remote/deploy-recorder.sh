JUJU_ENV=$1

juju set-env -e $JUJU_ENV "default-series=trusty"

echo 'conference-recorder:
  user: "bob"
  password: "1234"
  proxy: "52.28.141.175:5080"
  number: "+5555"
' > /tmp/conference-recorder.yaml

juju deploy -e $JUJU_ENV cs:~tads2015dataart/trusty/conference-recorder-2 conference-recorder --config /tmp/conference-recorder.yaml
juju add-relation -e $JUJU_ENV sms-feedback:recorder conference-recorder:api
juju expose -e $JUJU_ENV conference-recorder
 
