export JUJU_REPOSITORY=$PWD/charms/

juju set-env "default-series=trusty"

juju-deployer -c bundle-demo.yaml -c config-demo.yaml demo
