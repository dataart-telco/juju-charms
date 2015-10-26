
if [ "$#" -ge 1 ]; then
    JUJU_CUR_ENV=$1
else
    JUJU_CUR_ENV=`cat ~/.juju/current-environment`
fi

echo 'juju current env: '$JUJU_CUR_ENV

juju set-env -e $JUJU_CUR_ENV "default-series=trusty"

juju-deployer -e $JUJU_CUR_ENV -c tads2015-demo/bundle.yaml -c config-demo.yaml tads2015-demo

JUJU_PASS=$(grep password ~/.juju/environments/$JUJU_CUR_ENV.jenv | sed 's/.*: //g')

echo 'juju admin password: '$JUJU_PASS
juju set -e $JUJU_CUR_ENV monitor-server JUJU_API_PASSWORD=$JUJU_PASS

./bind-elaststic-ip.sh
