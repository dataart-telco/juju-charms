#!/bin/bash

export JUJU_REPOSITORY=$PWD/charms/

juju deploy local:trusty/monitor-agent-mesos monitor-agent-mesos
juju deploy local:trusty/monitor-agent-mesos-master monitor-agent-mesos-master
juju deploy local:trusty/monitor-agent-restcomm monitor-agent-restcomm

juju add-relation mesos-master monitor-agent-mesos
juju add-relation mesos-master monitor-agent-mesos-master
juju add-relation mesos-master monitor-agent-restcomm

juju add-relation mesos-slave monitor-agent-mesos

juju add-relation monitor-server monitor-agent-mesos
juju add-relation monitor-server monitor-agent-mesos-master
juju add-relation monitor-server monitor-agent-restcomm
