package main

import (
	"github.com/fsouza/go-dockerclient"
	"log"
	// 	"monitor-agent-docker/collectd"
	"monitor-agent-docker/collector"
	//	"os"
	"flag"
)

func main() {
	host := flag.String("url", "127.0.0.1", "Monitor server")
	flag.Parse()

	log.Println("Start agent with host =", *host)

	client, _ := docker.NewClient("unix:///var/run/docker.sock")
	writer := NewMonitorServerClient(*host)
	collector := collector.NewCollector(client, writer, 1)

	err := collector.Run(5)
	if err != nil {
		log.Fatal(err)
	}
}
