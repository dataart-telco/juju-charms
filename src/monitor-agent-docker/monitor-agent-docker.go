package main

import (
	"flag"
	"github.com/fsouza/go-dockerclient"
	"io"
	"io/ioutil"
	"monitor-agent-docker/collector"
	"os"
)

func main() {
	host := flag.String("url", "127.0.0.1", "Monitor server")
	period := flag.Int("t", 1, "Update period in seconds")
	l := flag.String("l", "INFO", "Log level: TRACE, INFO")

	flag.Parse()

	var traceHandle io.Writer
	if *l == "TRACE" {
		traceHandle = os.Stdout
	} else {
		traceHandle = ioutil.Discard
	}
	InitLog(traceHandle, os.Stdout, os.Stdout, os.Stderr)

	Info.Println("Start agent with host =", *host)

	client, _ := docker.NewClient("unix:///var/run/docker.sock")
	writer := NewMonitorServerClient(*host)
	collector := collector.NewCollector(client, writer, *period)

	err := collector.Run(5)
	if err != nil {
		Error.Fatal(err)
	}
}
