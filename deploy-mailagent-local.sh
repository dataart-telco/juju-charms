export JUJU_REPOSITORY=$PWD/charms/

echo 'mailagent:
  GMAIL_USER: "tads2015dataart@gmail.com" 
  GMAIL_PASS: "hlrcfhoswjjulqco"
  DUMP_TIMER: 5
' > /tmp/config-mailagent.yaml


juju deploy local:trusty/tads2015-mailagent-4mesos --config /tmp/config-mailagent.yaml mailagent
juju add-relation mailagent:redis redis-master:db
juju add-relation mailagent mesos-master
