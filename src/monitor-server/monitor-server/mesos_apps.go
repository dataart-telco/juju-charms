package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
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
	ScaleUp   int
	ScaleDown int
	Host      string
	Period    time.Duration
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

func (h *MesosAppsHandler) avgStat() (map[string]*Stat, []interface{}) {

	stats := make(map[string]*Stat)

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
		var stat *Stat
		stat = stats[m.AppId]
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

	for k, v := range stats {
		cpuLoad := v.CpuLoad1Avg

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

func (h *MesosAppsHandler) scaleUp(appId string) {
	h.scaleMesos("scale-up", appId)
}

func (h *MesosAppsHandler) scaleDown(appId string) {
	h.scaleMesos("scale-down", appId)
}

func (h *MesosAppsHandler) scaleMesos(action string, appId string) {
	Trace.Println("Scale mesos app:", appId, " action = ", action)

	delayKey := action + ":" + appId
	if isKey(delayKey) {
		Info.Println("ignore service scale, delay reason")
		return
	}

	instances, err := h.getAppInstances(appId)
	if err != nil {
		return
	}

	defer removeKeys(appId + ":")
	defer setBoolKey(delayKey, scaleDelay)

	if "scale-down" == action {
		if instances == 1 {
			Trace.Println("Ignore scale down! instances count =", instances)
			return
		}
		instances--

	} else if "scale-up" == action {
		instances++
	}
	h.scaleApp(instances, appId)
}

func (h *MesosAppsHandler) getAppInstances(appId string) (int, error) {
	url := "http://" + h.Host + "/v2/apps/" + appId

	Trace.Println("Get app state:", url)

	resp, err := http.Get(url)
	if err != nil {
		Warning.Println("can't load info for", appId)
		return 0, errors.New("load info for " + appId)
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		Warning.Println("Read body error", err)
		return 0, errors.New("read response body")
	}
	app := make(map[string]interface{})
	json.Unmarshal(body, &app)
	app = app["app"].(map[string]interface{})
	return int(app["instances"].(float64)), nil
}

func (h *MesosAppsHandler) scaleApp(instances int, appId string) {
	Info.Println("ScaleApp: ", appId, " to", instances)

	url := "http://" + h.Host + "/v2/apps/" + appId
	Trace.Println("scale app", appId, " to", instances, " url =", url)
	jsonStr := fmt.Sprintf("{\"instances\": %d}", instances)

	req, err := http.NewRequest("PUT", url, bytes.NewBufferString(jsonStr))
	req.Header.Set("X-Custom-Header", "myvalue")
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		Warning.Println("Send request error", err)
		return
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		Warning.Println("Read body error", err)
		return
	}
	Trace.Println("Update response", string(body))
}
