# This repo contains a set of charms and scripts

In the root of repo you can find all charms and scripts to deploy autoscale environment with **mesos** cluster, telscale-restcomm and set of value-add-services

#### Deploy scripts

1. **deploy-mesos.sh** - deploy mesos cluster to implement autoscale functionality - [result here](#deploy-mesossh)

#### Local installation with kvm

if you use nginx to expose installed apps you can use *update-nginx* script from *misc* folder to add juju_proxy config to nginx instance

```bash
sudo ./update-nginx tmpl_mesos.cfg
```

#### Apps
Repo contains a few apps which are wrapped to different charms with different installation ways

1. **tads2015-calls-consumer** - handles incomming call/sms and add it to datastorage
2. **tads2015-conference-call** - gets new participants from datastorage and adds them to conference
3. **tads2015-feedback-call** - drops conference and makes feedback call
4. **redis** - datastorage 
5. **telscale-restcomm** - restcomm server
6. **monitor-server** - managing server of custom simple monitoring system
7. **monitor-agent-mesos** - agent collects state of docker containers. It uses docker remote api to get statistics. This agent should be connected to all nodes of cluster
8. **monitor-agent-mesos-master** - agent collects state of mesos cluster. It uses marathon rest api to get statistics. This agent should be connected to master only.

#### Local charms

1. **tads2015-calls-consumer-4mesos** - wrapper for **calls-consumer** docker container to deploy to mesos cluster
2. **tads2015-conference-call-4mesos** - wrapper for **conference-call** docker container to deploy to mesos cluster
3. **tads2015-feedback-call-4mesos** - wrapper for **feedback-call** docker container to deploy to mesos cluster
4. **telscale-restcomm** - telscale restcomm charm with fixes in sql init files
5. **mesos-master** - patched original charm. Now it uses node hostname instead of *$JUJU_UNIT_NAME*.
6. **mesos-slave** - the same patch
7. **monitor-server** - monitoring system
8. **monitor-agent-mesos** - monitoring system
9. **monitor-agent-mesos-master** - monitoring system

## Autoscale

Our monitoring system collects state of each deployed mesos application and stet of mesos cluster.
Currently system uses cpu and memory usage only. 

One applicaiton can has a lot of instances. Statistics will be grouped. 

It allows to manage:
1. count of applicaitons instances 
2. count of mesos slave machines 

We use the foolowing rules:

1. if avg cpu usage of application(of all instances) is more than 70% system adds one more instance of this app.
2. if avg cpu usage of applicaiton(of all instances) is less than 10% system removes one instance of this app.
3. if mesos cluster cpu usage is more than 70% system adds mesos-slave node to environment
4. if mesos cluster cpu usage is less that 10% system removes mesos-slave node

#### deploy-mesos.sh

![juju-gui screenshot](https://dl.dropboxusercontent.com/u/8604560/mesos.png)

