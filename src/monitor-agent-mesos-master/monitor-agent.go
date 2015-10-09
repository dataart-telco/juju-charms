package main

import (
	"encoding/json"
	"flag"
	"io"
	"io/ioutil"
	"net/http"
	"net/url"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"
)

func WaitCtrlC() {
	var signal_channel chan os.Signal
	signal_channel = make(chan os.Signal, 2)
	signal.Notify(signal_channel, os.Interrupt, syscall.SIGTERM)
	<-signal_channel
}

func schedule(step int, what func()) {
	ticker := time.NewTicker(time.Duration(step) * time.Second)
	go func() {
		for {
			select {
			case <-ticker.C:
				what()
			}
		}
	}()
}

func sendData(host string, appId string, cpuLoad1 int, cpuLoad5 int, mem int) {
	pcName, _ := os.Hostname()

	resp, err := http.PostForm("http://"+host,
		url.Values{"date": {strconv.FormatInt(time.Now().UnixNano()/int64(time.Millisecond), 10)},
			"cpuLoad1":  {strconv.Itoa(cpuLoad1)},
			"cpuLoad5":  {strconv.Itoa(cpuLoad5)},
			"mem":       {strconv.Itoa(mem)},
			"appId":     {appId},
			"machineId": {pcName}})
	if err != nil {
		Error.Println("Error: ", err)
		return
	}
	Trace.Println("Send resp code:", resp.StatusCode)
}

func getMesosMetrics() (int, int, error) {
	resp, err := http.Get("http://127.0.0.1:5050/metrics/snapshot")
	if err != nil {
		return 0, 0, err
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return 0, 0, err
	}
	metrics := make(map[string]interface{})
	json.Unmarshal(body, &metrics)
	return int(metrics["master/cpus_percent"].(float64) * 100), int(metrics["master/mem_percent"].(float64) * 100), nil
}

func main() {
	host := flag.String("url", "127.0.0.1", "Monitor server")
	appId := flag.String("appId", "", "App id")
	l := flag.String("l", "INFO", "Log level: TRACE, INFO")

	flag.Parse()

	var traceHandle io.Writer
	if *l == "TRACE" {
		traceHandle = os.Stdout
	} else {
		traceHandle = ioutil.Discard
	}
	InitLog(traceHandle, os.Stdout, os.Stdout, os.Stderr)

	Info.Println("Start agent with host =", *host, " and appId =", *appId)

	do := func() {
		cpu, mem, err := getMesosMetrics()
		if err != nil {
			Error.Println("Load metrics error", err)
			return
		}
		Trace.Println("CPU: ", cpu)
		Trace.Println("Memory:", mem)

		sendData(*host, *appId, cpu, cpu, mem)
	}
	schedule(5, do)
	WaitCtrlC()
}
