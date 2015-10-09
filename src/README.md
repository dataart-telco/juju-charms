# Simple monitoring system 

Custom monitoring system to collect environment metrics and manage count deployed application instances and juju units

System is similar to collectd.

## Server

### Parameters 

1. -r - redist server host. example: 127.0.0.1:6379
2. -t - check state period in minutes
3. -p - Bind port
4. -cli-dir - juju cli script directory 
5. -d - delay scale actions in minutes
6. -m - Marathon host. example: 127.0.0.1:8080

### API

1. **/** - get current statistics
2. **/metrics** - save juju units metrics 
3. **/mesos/apps** - save mesos apps metrics

### metrics - POST form

1. date - long, unixtime
2. cpuLoad1 - int, 1 mins cpu load in percentages
3. cpuLoad5 = int, 5 mins cpu load in percentages
3. mem - int, in percentages
4. appId - string, juju charm name
5. machineId - string, hostname or *$JUJU_UNIT_NAME*

### mesos/apps - POST form

1. date - long, unixtime 
2. cpu - int, in percentages
3. mem - int, in percentages
4. appId - string, mesos application name
5. taskId - string, mesos task id

