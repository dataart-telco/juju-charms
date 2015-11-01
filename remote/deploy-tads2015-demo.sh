USE_EIP=0

print_usage(){
    printf "usage: [-i] [-e juju env]\n"
}

while getopts 'ie:' flag; do
    case "${flag}" in
        i)  USE_EIP=1 ;;
        e)  JUJU_CUR_ENV=$OPTARG ;;
        *)  print_usage
            exit 1
            ;;
   esac
done

if [ -z "$JUJU_CUR_ENV" ]; then
    echo "Get default Jujuj environment"
    JUJU_CUR_ENV=`cat ~/.juju/current-environment`
fi

echo 'juju current env: '$JUJU_CUR_ENV

juju set-env -e $JUJU_CUR_ENV "default-series=trusty"

juju-deployer -e $JUJU_CUR_ENV -c tads2015-demo/bundle.yaml

JUJU_PASS=$(grep password ~/.juju/environments/$JUJU_CUR_ENV.jenv | sed 's/.*: //g')

echo 'juju admin password: '$JUJU_PASS
juju set -e $JUJU_CUR_ENV monitor-server JUJU_API_PASSWORD=$JUJU_PASS
juju add-relation -e $JUJU_CUR_ENV monitor-server:api-server juju-gui:web

if [ $USE_EIP -eq 1 ]; then

    echo 'Try to bind elastic ip to restcomm'

    juju set -e $JUJU_CUR_ENV telscale-restcomm static_ip=52.28.141.175
    ./bind-elaststic-ip.sh
fi
