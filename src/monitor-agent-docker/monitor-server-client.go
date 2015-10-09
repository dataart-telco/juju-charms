package main

import (
	"github.com/fsouza/go-dockerclient"
	"monitor-agent-docker/collector"
	"net/http"
	"net/url"
	"strconv"
	"time"
)

type MonitorServerClient struct {
	host string
}

func NewMonitorServerClient(host string) MonitorServerClient {
	return MonitorServerClient{
		host: host,
	}
}

func (c MonitorServerClient) Write(s collector.Stats) error {
	Trace.Println("Try to sent data to server")

	var v *docker.Stats
	v = &s.Stats

	var memPercent = 0.0
	var cpuPercent = 0.0

	// MemoryStats.Limit will never be 0 unless the container is not running and we havn't
	// got any data from cgroup
	if v.MemoryStats.Limit != 0 {
		memPercent = float64(v.MemoryStats.Usage) / float64(v.MemoryStats.Limit) * 100.0
	}

	cpuPercent = getCPUPercent(v)

	Trace.Println("cpu =", cpuPercent, "mem = ", memPercent)

	c.sendData(s.App, s.Task, int(cpuPercent), int(memPercent))

	return nil
}

func (c MonitorServerClient) sendData(appId string, taskId string, cpuLoad int, mem int) {

	resp, err := http.PostForm("http://"+c.host,
		url.Values{
			"date":   {strconv.FormatInt(time.Now().UnixNano()/int64(time.Millisecond), 10)},
			"cpu":    {strconv.Itoa(cpuLoad)},
			"mem":    {strconv.Itoa(mem)},
			"appId":  {appId},
			"taskId": {taskId}})

	if err != nil {
		Error.Println("Error: ", err)
		return
	}
	Trace.Println("Send resp code:", resp.StatusCode)
}

func getCPUPercent(s *docker.Stats) float64 {
	return calculateCPUPercent(s.PreCPUStats.CPUUsage.TotalUsage, s.PreCPUStats.SystemCPUUsage, s)
}

//copypaste from docker client
//https://github.com/docker/docker/blob/master/api/client/stats.go#L205
func calculateCPUPercent(previousCPU, previousSystem uint64, v *docker.Stats) float64 {
	var (
		cpuPercent = 0.0
		// calculate the change for the cpu usage of the container in between readings
		cpuDelta = float64(v.CPUStats.CPUUsage.TotalUsage - previousCPU)
		// calculate the change for the entire system between readings
		systemDelta = float64(v.CPUStats.SystemCPUUsage - previousSystem)
	)

	if systemDelta > 0.0 && cpuDelta > 0.0 {
		cpuPercent = (cpuDelta / systemDelta) * float64(len(v.CPUStats.CPUUsage.PercpuUsage)) * 100.0
	}
	return cpuPercent
}
