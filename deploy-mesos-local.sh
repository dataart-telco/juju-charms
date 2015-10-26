export JUJU_REPOSITORY=$PWD/charms/

if [ "$#" -ge 1 ]; then
	JUJU_CUR_ENV=$1
else
	JUJU_CUR_ENV=`cat ~/.juju/current-environment`
fi

echo 'juju current env: '$JUJU_CUR_ENV

juju set-env -e $JUJU_CUR_ENV "default-series=trusty"
#juju set-constraints "mem=512M"
#juju set-constraints 'instance-type=m1.small'


juju-deployer -e $JUJU_CUR_ENV -c bundle-demo-mesos-local.yaml -c config-demo.yaml demo

JUJU_PASS=$(grep password ~/.juju/environments/$JUJU_CUR_ENV.jenv | sed 's/.*: //g')

echo 'juju admin password: '$JUJU_PASS
juju set -e $JUJU_CUR_ENV monitor-server JUJU_API_PASSWORD=$JUJU_PASS 
