# This repo contains a set of charms and scripts

#### Deploy scripts

1. **deploy-standalone.sh** - deploy system with autoscale functionality - [result here](#deploy-standalonesh)
2. **deploy-kube.sh** - deploy apps with kubernetes 

#### Apps
Repo contains a few apps which are wrapped to different charms with different installation ways

1. **tads2015-calls-consumer** - handles incomming call/sms and add it to datastorage
2. **tads2015-conference-call** - gets new participants from datastorage and adds them to conference
3. **tads2015-feedback-call** - drops conference and makes feedback call
4. **redis** - datastorage 
5. **telscale**-restcomm - 

#### Charms

1. docker-charm/ - git submodule for docker-charm

2. flannel-docker-charm/ - git submodule docker-charm

3. kubernetes-master/ - kubernetes master v.1.0.3

4. redis-master-4kube/ - wrapper for redis docker container. contains pod and service for kubernetes

5. tads2015-calls-consumer/ - standalone charm with calls-consumer app

6. tads2015-calls-consumer-4kube/ - wrapper for **calls-consumer** docker container. contains pod and service for kubernetes

7. tads2015-conference-call-4kube/ - wrapper for **conference-call** docker container. contains pod and service for kubernetes

8. tads2015-feedback-call-4kube/ - wrapper for **feedback-call** docker container. contains pod and service for kubernetes

9. telscale-restcomm/ - telscale restcomm charm with fixes in sql init files

#### deploy-standalone.sh

![juju-gui screenshot](https://dl.dropboxusercontent.com/u/8604560/juju-standalone-scale.png)
