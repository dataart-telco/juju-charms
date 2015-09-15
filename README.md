This repo contains a set of charms and scripts

deploy-kube.sh - main script to deploy the whole bundle

Charms
docker-charm/ - empty
flannel-docker-charm/ - empty
kubernetes-master/ - kubernetes master
redis-master-4kube/ - redis (for storing incoming phone numbers)
tads2015-calls-consumer/ - for testing purposes
tads2015-calls-consumer-4kube/ - stores incoming numbers to database
tads2015-conference-call-4kube/ - collects incoming numbers from database and add them to conference
tads2015-feedback-call-4kube/ - Drops conference and makes feedback call
telscale-restcomm/ - deploys telscale and restcomm
