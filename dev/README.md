# In development charms and scripts.

This folder contains a set of charms and scripts to deploy different environment variants.

**NOTE** you should move this folder to root repo if you want to deploy something. it doesn't contain all part of environment!!!


1. **kubernetes** - use kubernetes cluster to deploy value-add-services - *deploy-kube.sh*
2. **standalone** - use single docker insatnces to deploy value-add-services - [deploy-standalone.sh](#deploy-standalonesh)
3. **zabbix** - use standalone deploy and zabbix monitor system - *deploy_zabbix.sh*

#### Apps
Repo contains a few apps which are wrapped to different charms with different installation ways

1. **tads2015-calls-consumer** - handles incomming call/sms and add it to datastorage
2. **tads2015-conference-call** - gets new participants from datastorage and adds them to conference
3. **tads2015-feedback-call** - drops conference and makes feedback call
4. **redis** - datastorage 
5. **telscale-restcomm** - restcomm server

#### Charms

1. docker-charm/ - git submodule for docker-charm

2. flannel-docker-charm/ - git submodule docker-charm

3. kubernetes-master/ - kubernetes master v.1.0.3

4. redis-master-4kube/ - wrapper for redis docker container. contains pod and service for kubernetes

5. tads2015-calls-consumer/ - standalone charm with calls-consumer app

6. tads2015-calls-consumer-4kube/ - wrapper for **calls-consumer** docker container. contains pod and service for kubernetes

7. tads2015-conference-call-4kube/ - wrapper for **conference-call** docker container. contains pod and service for kubernetes

8. tads2015-feedback-call-4kube/ - wrapper for **feedback-call** docker container. contains pod and service for kubernetes

#### deploy-standalone.sh

![juju-gui screenshot](https://dl.dropboxusercontent.com/u/8604560/juju-standalone-scale.png)
