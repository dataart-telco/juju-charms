export JUJU_REPOSITORY=$PWD/charms/

juju set-env "default-series=trusty"
#juju set-constraints mem=768M
juju set-constraints 'instance-type=m1.small'

juju-deployer -c bundle-demo-standalone.yaml -c config-demo.yaml demo

