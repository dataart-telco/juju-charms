package main

import (
	"net/http"
	"os/exec"
	"strconv"
	"time"

	"encoding/json"
	"fmt"
)

type Metrics struct {
	Date      uint64
	CpuLoad1  int
	CpuLoad5  int
	Mem       int
	AppId     string
	MachineId string
}

type JujuCharmHandler struct {
	ScaleDelay int
	ScaleUp    int
	ScaleDown  int
	Period     time.Duration
	CliDir     string
}

func (h *JujuCharmHandler) handleMetrics(w http.ResponseWriter, r *http.Request) {
	m := Metrics{}
	m.Date, _ = strconv.ParseUint(r.FormValue("date"), 10, 64)

	m.CpuLoad1, _ = strconv.Atoi(r.FormValue("cpuLoad1"))
	m.CpuLoad5, _ = strconv.Atoi(r.FormValue("cpuLoad5"))
	m.Mem, _ = strconv.Atoi(r.FormValue("mem"))
	m.AppId = r.FormValue("appId")
	m.MachineId = r.FormValue("machineId")

	bytes, _ := json.Marshal(&m)
	value := string(bytes)

	db := NewDbClient(ipRedis)
	key := "metric:" + m.AppId + ":" + m.MachineId // + ":" + strconv.FormatUint(m.Date, 10);

	Trace.Println("Add stat for", key)

	db.Set(key, value, 5*time.Minute)

	fmt.Fprintf(w, value)
}

func (h *JujuCharmHandler) checkState() {
	Trace.Println("checkState")

	stats, _ := h.avgStat()

	for k, v := range stats {
		cpuLoad := v.CpuLoad1Avg
		if h.Period.Minutes() > 1 {
			cpuLoad = v.CpuLoad5Avg
		}

		Trace.Println("stateChecker: ", k, " -> cpu =", cpuLoad, "; mem =", v.MemAvg)
		if cpuLoad > h.ScaleUp {
			Info.Println("\tscaleUp: ", k, " -> cpu =", cpuLoad, "; mem =", v.MemAvg)
			h.scaleUp(k)
		} else if cpuLoad < h.ScaleDown {
			Info.Println("\tscaleDown: ", k, " -> cpu =", cpuLoad, "; mem =", v.MemAvg)
			h.scaleDown(k)
		}
	}
}

func (h *JujuCharmHandler) scaleUp(service string) {
	h.scaleJuju("add-unit", service)
}

func (h *JujuCharmHandler) scaleDown(service string) {
	h.scaleJuju("scale-down", service)
}

func (h *JujuCharmHandler) scaleJuju(action string, service string) {
	delayKey := action + ":" + service
	if isKey(delayKey) {
		Info.Println("ignore service scale, delay reason")
		return
	}

	Trace.Println("scaleJuju -> ", service, " -> action =", action)
	out, _ := exec.Command(h.CliDir+"/jujuapicli", "-c", h.CliDir+"/.jujuapi.yaml", action, service).Output()
	Trace.Println("<-", string(out))

	removeKeys(service + ":*")
	setBoolKey(delayKey, h.ScaleDelay)
}

func (h *JujuCharmHandler) avgStat() (map[string]*Stat, []interface{}) {

	stats := make(map[string]*Stat)

	db := NewDbClient(ipRedis)

	keys := db.Keys("metric:*").Val()
	metrics := make([]interface{}, len(keys))

	for i, key := range keys {
		val := db.Get(key).Val()
		m := Metrics{}
		err := json.Unmarshal([]byte(val), &m)
		if err != nil {
			continue
		}
		metrics[i] = m

		if _, ok := stats[m.AppId]; !ok {
			stats[m.AppId] = &Stat{}
		}
		var stat *Stat
		stat = stats[m.AppId]
		stat.CpuLoad1 += m.CpuLoad1
		stat.CpuLoad5 += m.CpuLoad5
		stat.MemSum += m.Mem
		stat.Count++

		stat.CpuLoad1Avg = stat.CpuLoad1 / stat.Count
		stat.CpuLoad5Avg = stat.CpuLoad5 / stat.Count
		stat.MemAvg = stat.MemSum / stat.Count
	}

	return stats, metrics
}
