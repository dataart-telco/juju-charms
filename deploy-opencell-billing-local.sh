export JUJU_REPOSITORY=$PWD/charms/

echo 'opencell-billing:
  OPENCELL_PASSWORD: "Basic bWV2ZW8uYWRtaW46bWV2ZW8uYWRtaW4=" 
' > /tmp/config-opencell-billing.yaml


juju deploy local:trusty/opencell-billing-4mesos --config /tmp/config-opencell-billing.yaml opencell-billing
juju add-relation opencell-billing:redis redis-master:db
juju add-relation opencell-billing:restcomm restcomm:website
juju add-relation opencell-billing:opencell opencell:opencell
juju add-relation opencell-billing mesos-master
