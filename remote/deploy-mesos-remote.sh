
juju set-env "default-series=trusty"

juju-deployer -c bundle-demo-mesos-remote.yaml -c config-demo.yaml demo

JUJU_CUR_ENV=`cat ~/.juju/current-environment`

echo 'juju current env: '$JUJU_CUR_ENV

JUJU_PASS=$(grep password ~/.juju/environments/$JUJU_CUR_ENV.jenv | sed 's/.*: //g')

echo 'juju admin password: '$JUJU_PASS
juju set monitor-server JUJU_API_PASSWORD=$JUJU_PASS
