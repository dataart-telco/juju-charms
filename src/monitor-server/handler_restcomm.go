package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"time"
)

type RestcommMetrics struct {
	Date   uint64
	AppId  string
	TaskId string

	MaxLiveCalls          int
	LiveCalls             int
	LiveOutgoingCalls     int
	LiveIncomingCalls     int
	TotalCallsSinceUptime int
	CompletedCalls        int
	FailedCalls           int
}

type RestcommAppHandler struct {
	ScaleUp    int
	ScaleDown  int
	Host       string
	Period     time.Duration
	ScaleDelay int
	marathonClient MarathonClient
}

type RestcommAvgMetrics struct {
	Count        int
	LiveCalls    int
	LiveCallsAvg int
}

func NewRestcommAppHandler(scaleUp int, scaleDown  int, period time.Duration, scaleDelay int, host string) *RestcommAppHandler{
	return &RestcommAppHandler{ScaleUp: scaleUp, ScaleDown: scaleDown, Period: period, ScaleDelay: scaleDelay, 
		marathonClient: MarathonClient{Host: host, ScaleDelay: scaleDelay}}
}

func (h *RestcommAppHandler) handleMetrics(w http.ResponseWriter, r *http.Request) {
	Trace.Println("Restcomm app handler")
	m := RestcommMetrics{}
	m.Date, _ = strconv.ParseUint(r.FormValue("date"), 10, 64)
	m.AppId = r.FormValue("appId")
	m.TaskId = r.FormValue("taskId")

	m.MaxLiveCalls, _ = strconv.Atoi(r.FormValue("maxLiveCalls"))
	m.LiveCalls, _ = strconv.Atoi(r.FormValue("liveCalls"))
	m.LiveOutgoingCalls, _ = strconv.Atoi(r.FormValue("liveOutgoingCalls"))
	m.LiveIncomingCalls, _ = strconv.Atoi(r.FormValue("liveIncomingCalls"))
	m.TotalCallsSinceUptime, _ = strconv.Atoi(r.FormValue("totalCallsSinceUptime"))
	m.CompletedCalls, _ = strconv.Atoi(r.FormValue("completedCalls"))
	m.FailedCalls, _ = strconv.Atoi(r.FormValue("failedCalls"))

	bytes, _ := json.Marshal(&m)
	value := string(bytes)

	db := NewDbClient(ipRedis)
	key := "restcomm:" + m.AppId + ":" + m.TaskId + ":" + strconv.FormatUint(m.Date, 10)

	Trace.Println("Add stat for restcomm", key)
	Trace.Println(string(bytes))

	db.Set(key, value, h.Period)

	fmt.Fprintf(w, value)
}

func (h *RestcommAppHandler) avgStat() (map[string]interface{}, []interface{}) {

	stats := make(map[string]interface{})

	db := NewDbClient(ipRedis)

	keys := db.Keys("restcomm:*").Val()
	metrics := make([]interface{}, len(keys))

	for i, key := range keys {
		val := db.Get(key).Val()
		m := RestcommMetrics{}
		err := json.Unmarshal([]byte(val), &m)
		if err != nil {
			continue
		}
		metrics[i] = m

		if _, ok := stats[m.AppId]; !ok {
			stats[m.AppId] = &RestcommAvgMetrics{}
		}
		stat := stats[m.AppId].(*RestcommAvgMetrics)
		stat.Count++
		stat.LiveCalls += int((float64(m.LiveCalls) / float64(m.MaxLiveCalls)) * 100.0)

		stat.LiveCallsAvg = stat.LiveCalls / stat.Count
	}

	return stats, metrics
}

func (h *RestcommAppHandler) checkState() {
	Trace.Println("checkState")

	stats, _ := h.avgStat()

	for k, e := range stats {
		v := e.(*RestcommAvgMetrics)
		callsLoad := v.LiveCallsAvg

		Trace.Println("stateChecker: ", k, " -> calls =", callsLoad)
		if callsLoad > h.ScaleUp {
			Info.Println("\tscaleUp: ", k, " -> calls =", callsLoad)
			h.marathonClient.scaleUp(k)
		} else if callsLoad < h.ScaleDown {
			Info.Println("\tscaleDown: ", k, " -> calls =", callsLoad)
			h.marathonClient.scaleDown(k)
		}
	}
}
