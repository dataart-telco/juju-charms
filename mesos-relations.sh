#!/bin/bash

juju add-relation mesos-master mesos-slave
juju add-relation monitor-agent-mesos:monitor-server monitor-server:monitor-server
juju add-relation monitor-agent-mesos mesos-master
juju add-relation monitor-agent-mesos mesos-slave  
juju add-relation monitor-agent-mesos-master:monitor-server monitor-server:monitor-server
juju add-relation monitor-agent-mesos-master mesos-master  
juju add-relation monitor-server mesos-master