package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"time"
)

type MesosAppMetrics struct {
	Date   uint64
	Cpu    int
	Mem    int
	AppId  string
	TaskId string
}

type MesosAppsHandler struct {
	ScaleUp    int
	ScaleDown  int
	Host       string
	Period     time.Duration
	ScaleDelay int
	marathonClient MarathonClient
}

func NewMesosAppsHandler(scaleUp int, scaleDown  int, period time.Duration, scaleDelay int, host string) *MesosAppsHandler {
	return &MesosAppsHandler{ScaleUp: scaleUp, ScaleDown: scaleDown, Period: period, ScaleDelay: scaleDelay, 
		marathonClient: MarathonClient{Host: host, ScaleDelay: scaleDelay}}
}

func (h *MesosAppsHandler) handleMetrics(w http.ResponseWriter, r *http.Request) {
	Trace.Println("Mesos app handler")
	m := MesosAppMetrics{}
	m.Date, _ = strconv.ParseUint(r.FormValue("date"), 10, 64)

	m.Cpu, _ = strconv.Atoi(r.FormValue("cpu"))
	m.Mem, _ = strconv.Atoi(r.FormValue("mem"))
	m.AppId = r.FormValue("appId")
	m.TaskId = r.FormValue("taskId")

	bytes, _ := json.Marshal(&m)
	value := string(bytes)

	db := NewDbClient(ipRedis)
	key := "mesos:" + m.AppId + ":" + m.TaskId + ":" + strconv.FormatUint(m.Date, 10)

	Trace.Println("Add stat for mesos:", key)

	db.Set(key, value, h.Period)

	fmt.Fprintf(w, value)
}

func (h *MesosAppsHandler) avgStat() (map[string]interface{}, []interface{}) {

	stats := make(map[string]interface{})

	db := NewDbClient(ipRedis)

	keys := db.Keys("mesos:*").Val()
	metrics := make([]interface{}, len(keys))

	for i, key := range keys {
		val := db.Get(key).Val()
		m := MesosAppMetrics{}
		err := json.Unmarshal([]byte(val), &m)
		if err != nil {
			continue
		}
		metrics[i] = m

		if _, ok := stats[m.AppId]; !ok {
			stats[m.AppId] = &Stat{}
		}
		stat := stats[m.AppId].(*Stat)
		stat.CpuLoad1 += m.Cpu
		stat.MemSum += m.Mem
		stat.Count++

		stat.CpuLoad1Avg = stat.CpuLoad1 / stat.Count
		stat.CpuLoad5Avg = stat.CpuLoad5 / stat.Count
		stat.MemAvg = stat.MemSum / stat.Count
	}

	return stats, metrics
}

func (h *MesosAppsHandler) checkState() {
	Trace.Println("checkState")

	stats, _ := h.avgStat()

	for k, e := range stats {
		v := e.(*Stat)
		cpuLoad := v.CpuLoad1Avg

		Trace.Println("stateChecker: ", k, " -> cpu =", cpuLoad, "; mem =", v.MemAvg)
		if cpuLoad > h.ScaleUp {
			Info.Println("\tscaleUp: ", k, " -> cpu =", cpuLoad, "; mem =", v.MemAvg)
			h.marathonClient.scaleUp(k)
		} else if cpuLoad < h.ScaleDown {
			Info.Println("\tscaleDown: ", k, " -> cpu =", cpuLoad, "; mem =", v.MemAvg)
			h.marathonClient.scaleDown(k)
		}
	}
}


