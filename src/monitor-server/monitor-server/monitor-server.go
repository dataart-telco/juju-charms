package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"time"
	//	"os/exec"
	//	"strconv"
	//	"time"
)

type Stat struct {
	MemSum   int
	CpuLoad1 int
	CpuLoad5 int
	Count    int

	MemAvg      int
	CpuLoad1Avg int
	CpuLoad5Avg int
}

type HttpHandler func(http.ResponseWriter, *http.Request)

type MetricsHandler interface {
	handleMetrics(w http.ResponseWriter, r *http.Request)
	checkState()
	avgStat() (map[string]*Stat, []interface{})
}

var pages map[string]HttpHandler

var ipRedis string
var scaleDelay int

var handlers []MetricsHandler

func handleGet(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	Trace.Println("\thandleGet")

	h := handlers[0]
	stats, metrics := h.avgStat()

	jm1, _ := json.Marshal(metrics)
	jm2, _ := json.Marshal(stats)

	juju := fmt.Sprintf("{\"avg\": %s, \"data\": %s}", jm2, jm1)

	h2 := handlers[1]
	stats2, metrics2 := h2.avgStat()
	jm21, _ := json.Marshal(metrics2)
	jm22, _ := json.Marshal(stats2)

	mesos := fmt.Sprintf("{\"avg\": %s, \"data\": %s}", jm22, jm21)

	fmt.Fprintf(w, "{\"charm\": %s, \"mesos:\": %s}", juju, mesos)
}

func initHandlers() {
	pages = make(map[string]HttpHandler)
	pages["/"] = handleGet
	pages["/metrics"] = handlers[0].handleMetrics
	pages["/mesos/apps"] = handlers[1].handleMetrics
}

func httpHandlerPlay(w http.ResponseWriter, r *http.Request) {
	Trace.Println("\t<- http request -", r.URL.Path)

	f := pages[r.URL.Path]
	if f != nil {
		f(w, r)
		return
	}
	w.WriteHeader(http.StatusNotFound)
}

func start(port int) {
	Info.Println("Start web server")
	initHandlers()
	http.HandleFunc("/", httpHandlerPlay)
	err := http.ListenAndServe(fmt.Sprintf(":%d", port), nil)
	if err != nil {
		panic(err)
	}
}

func main() {
	host := flag.String("r", "127.0.0.1:6379", "Redis server")
	t := flag.Int("t", 5, "Avg period in minutes")
	port := flag.Int("p", 8080, "Bind port")
	cli := flag.String("cli-dir", "/var/lib/simple-monitor-service", "cli directory command")
	d := flag.Int("d", 10, "delay scale actions ")
	m := flag.String("m", "127.0.0.1:8080", "Marathon host")
	l := flag.String("l", "INFO", "Log level: TRACE, INFO")

	up := flag.Int("up", 70, "Scale up limit")
	down := flag.Int("down", 30, "Scale down limit")

	flag.Parse()

	var traceHandle io.Writer
	if *l == "TRACE" {
		traceHandle = os.Stdout
	} else {
		traceHandle = ioutil.Discard
	}
	InitLog(traceHandle, os.Stdout, os.Stdout, os.Stderr)

	Info.Println("Start server with port =", *port,
		"| check period =", *t, "min(s)",
		"| redisHost =", *host,
		"| cli dir =", *cli,
		"| scale delay =", *d,
		"| marathon host =", *m,
		"| log level =", *l,
		"| upLimit =", *up,
		"| downLimit =", *down)

	ipRedis = *host
	scaleDelay = *d

	handlers = make([]MetricsHandler, 2)
	handlers[0] = &JujuCharmHandler{Period: *t, CliDir: *cli, ScaleUp: *up, ScaleDown: *down}
	handlers[1] = &MesosAppsHandler{Period: time.Duration(*t) * time.Minute, Host: *m, ScaleUp: *up, ScaleDown: *down}

	resetDb()

	//timeout in seconds
	for _, h := range handlers {
		schedule((*t * 60), h.checkState)
	}

	start(*port)
}
