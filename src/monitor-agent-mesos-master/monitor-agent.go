package main

import (
	"encoding/json"
	"flag"
	"io/ioutil"
	"log"
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
		log.Println("Error: ", err)
		return
	}
	log.Println("Send resp code:", resp.StatusCode)
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

	flag.Parse()

	log.Println("Start agent with host =", *host, " and appId =", *appId)

	do := func() {
		cpu, mem, err := getMesosMetrics()
		if err != nil {
			log.Println("Load metrics error", err)
			return
		}
		log.Println("CPU: ", cpu)
		log.Println("Memory:", mem)

		sendData(*host, *appId, cpu, cpu, mem)
	}
	schedule(5, do)
	WaitCtrlC()
}
