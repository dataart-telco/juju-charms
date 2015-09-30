export JUJU_REPOSITORY=$PWD/charms/

juju set-env "default-series=trusty"
juju set-constraints "mem=768M"
#juju set-constraints 'instance-type=m1.small'

juju-deployer -c bundle-demo-mesos.yaml -c config-demo.yaml demo

JUJU_CUR_ENV=`cat ~/.juju/current-environment`

echo 'juju current env: '$JUJU_CUR_ENV

JUJU_PASS=$(grep password ~/.juju/environments/$JUJU_CUR_ENV.jenv | sed 's/.*: //g')

echo 'juju admin password: '$JUJU_PASS
juju set monitor-server JUJU_API_PASSWORD=$JUJU_PASS
