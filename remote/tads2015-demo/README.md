#DataArt's demo bundle

1. Deploy value add services to mesos cluster.

2. Audo scale of environment: applications count and mesos cluster(add juju unit of mesos-slave)

##Configuration of bundle

The following services of bundle require extra configuration

1. telscale-restcomm
  1. voicerss_key - you should specify API key form coicerss service
  2. init_password - you can change admin password during setup prcess
  3. static_ip - if you use AWS elastic IP you can specify it here (optional)
2. monitor-server
  1. JUJU_API_HOST - you can specify IP address of juju-gui if you don't have ability to make relation between this charm and juju-gui charm
  2. JUJU_API_PASSWORD  - you should specify admin password of juju-gui

##Value add services configuration

You can specify restcomm uase and password for our value add services 

Also you can specify phone number for some services too

