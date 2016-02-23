package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"net/url"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"
)

type MesosTask struct {
	Id   string `json:"id"`
	Host string `json:"host"`
}

type MesosResponse struct {
	Tasks []MesosTask `json:"tasks"`
}

type RestcommMetrics struct {
	LiveCalls             int
	LiveOutgoingCalls     int
	LiveIncomingCalls     int
	TotalCallsSinceUptime int
	CompletedCalls        int
	FailedCalls           int
}

type RestcommResponse struct {
	InstanceId string
	Metrics    RestcommMetrics
}

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

func sendData(monitorHost string, appId string, taskId string, data *RestcommResponse) {
	code, err := Post("http://" + monitorHost, 
		url.Values{"date": {strconv.FormatInt(time.Now().UnixNano()/int64(time.Millisecond), 10)},
			"maxLiveCalls":          {strconv.Itoa(restcommMaxCalls)},
			"liveCalls":             {strconv.Itoa(data.Metrics.LiveCalls)},
			"liveOutgoingCalls":     {strconv.Itoa(data.Metrics.LiveOutgoingCalls)},
			"liveIncomingCalls":     {strconv.Itoa(data.Metrics.LiveIncomingCalls)},
			"totalCallsSinceUptime": {strconv.Itoa(data.Metrics.TotalCallsSinceUptime)},
			"completedCalls":        {strconv.Itoa(data.Metrics.CompletedCalls)},
			"failedCalls":           {strconv.Itoa(data.Metrics.FailedCalls)},
			"appId":                 {appId},
			"taskId":                {taskId}}.Encode())
	if err != nil {
		Error.Println("Error: ", err)
		return
	}
	Trace.Println("Send resp code:", code)
}

func collectMetrics(marathonHost string, appId string, monitorHost string) {
	_, body, err := Get("http://" + marathonHost + "/v2/apps/" + appId + "/tasks")
	if err != nil {
		Error.Println("Get tasks error:", err)
		return
	}
	Trace.Println("Get tasks for", appId, ": ", string(body))

	var respData MesosResponse
	err = json.Unmarshal(body, &respData)
	if err != nil {
		Error.Println("Parse response error:", err)
		return
	}

	for _, e := range respData.Tasks {
		data, err := getRestCommCallStat(e.Host)
		if err != nil {
			Error.Println("Get restcomm metrics error:", err)
			continue
		}
		sendData(monitorHost, appId, e.Id, data)
	}
}

func getRestCommCallStat(host string) (*RestcommResponse, error) {

	url := fmt.Sprintf("http://%s:%s@%s:%d/restcomm/2012-04-24/Accounts/%s/Supervisor.json/metrics",
		restcommUser, restcommPswd, host, restcommPort, restcommUser)

	Trace.Println("Try get data by url:", url)

	_, body, err := Get(url)
	if err != nil {
		return nil, err
	}
	Trace.Println("RestcommMetrics:", string(body))

	var restcommData RestcommResponse
	json.Unmarshal(body, &restcommData)

	return &restcommData, nil
}

var restcommUser string
var restcommPswd string
var restcommPort int
var restcommMaxCalls int

func main() {
	restcommPort = 8090
	restcommUser = "ACae6e420f425248d6a26948c17a9e2acf"
	restcommPswd = "42d8aa7cde9c78c4757862d84620c335"

	monitorHost := flag.String("url", "127.0.0.1", "Monitor server")
	appId := flag.String("appId", "restcomm", "App id")
	marathonHost := flag.String("m", "127.0.0.1:8080", "Marathon host")

	rPort := flag.Int("rPort", 8090, "Restcomm Port")
	rUser := flag.String("rUser", "ACae6e420f425248d6a26948c17a9e2acf", "Restcomm user")
	rPswd := flag.String("rPswd", "42d8aa7cde9c78c4757862d84620c335", "Restcomm password")
	maxCalls := flag.Int("max", 50, "Max calls")

	l := flag.String("l", "INFO", "Log level: TRACE, INFO")

	flag.Parse()

	restcommPort = *rPort
	restcommPswd = *rPswd
	restcommUser = *rUser
	restcommMaxCalls = *maxCalls

	var traceHandle io.Writer
	if *l == "TRACE" {
		traceHandle = os.Stdout
	} else {
		traceHandle = ioutil.Discard
	}
	InitLog(traceHandle, os.Stdout, os.Stdout, os.Stderr)

	Info.Println("Start agent with host =", *monitorHost, " and appId =", *appId, "| period 5 sec")

	do := func() {
		collectMetrics(*marathonHost, *appId, *monitorHost)
	}
	schedule(5, do)
	WaitCtrlC()
}
