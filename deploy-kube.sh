export JUJU_REPOSITORY=$PWD/charms/

juju set-env "default-series=trusty"
juju set-constraints mem=1G

juju-deployer -c bundle-demo-kube.yaml -c config-demo.yaml demo

