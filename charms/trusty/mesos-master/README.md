#Fork with some fixes 

#What is Mesos?
###A distributed systems kernel

Mesos is built using the same principles as the Linux kernel, only at a different level of abstraction. The Mesos kernel runs on every machine and provides applications (e.g., Hadoop, Spark, Kafka, Elastic Search) with API’s for resource management and scheduling across entire datacenter and cloud environments.

##Mesos Features

  - Scalability to 10,000s of nodes
  - Fault-tolerant replicated master and slaves using ZooKeeper
  - Support for Docker containers
  - Native isolation between tasks with Linux Containers
  - Multi-resource scheduling (memory, CPU, disk, and ports)
  - Java, Python and C++ APIs for developing new parallel applications
  - Web UI for viewing cluster state

# Overview

This charm install Mesos based on Mesosphere's packages and instructions. Refer to: [Mesosphere mesos cluster instalation instructions](https://open.mesosphere.com/getting-started/datacenter/install/)

## Charm features:

  - Runs mesos master (standalone and cluster modes)
  - Runs Marathon
  - Option to install zookeeper
  - Option to run mesos slave on same machine
  - Option to install docker
  - Option to install mesos-dns

# Usage

    juju deploy mesos-master
    juju expose mesos-master

### Endepoints

Mesos web ui: http://<server ip>:5050
Marathon: http://<server ip>:8080

For full description of the options refer to:

  - [Mesosphere mesos master configuration](https://open.mesosphere.com/reference/mesos-master/)
  - [Mesosphere mesos slave configuration](https://open.mesosphere.com/reference/mesos-slave/)
  - [Apache Mesos documentation](http://mesos.apache.org/documentation/latest/configuration/)

  - [Apache Zookeeper configuration](https://zookeeper.apache.org/doc/r3.4.6/zookeeperAdmin.html#sc_configuration)
  - [Mesos-dns configuration](https://mesosphere.github.io/mesos-dns/docs/configuration-parameters.html)

### This Charm is in beta and not all mesos-slave options are available at the moment. Let me know if you require any option or feel free to contribute.

## Known Limitations and Issues

#### Local Provider Blockers

 The Docker Charm will not work out of the box on the
 [local provider](https://jujucharms.com/docs/config-local). LXC containers are goverend by a
 very strict [App Armor](https://wiki.ubuntu.com/AppArmor)
 [policy](https://help.ubuntu.com/lts/serverguide/lxc.html#lxc-apparmor) that prevents accidental
 misuses of privilege inside the container. Thus **running the mesos-slave Charm with docker containerizer
 inside the local provider is not a supported deployment method**.

# TODO
  - Marathon Options
  - Missing mesos master options
  - Missing mesos slave options
  - Missing Options
  - Tests
