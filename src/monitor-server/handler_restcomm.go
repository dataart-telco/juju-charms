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

type RestcommMetrics struct {
	Date   uint64
	AppId  string
	TaskId string

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
	MaxCalls   int
}

type RestcommAvgMetrics struct {
	Count        int
	LiveCalls    int
	LiveCallsAvg int
}

func (h *RestcommAppHandler) handleMetrics(w http.ResponseWriter, r *http.Request) {
	Trace.Println("Restcomm app handler")
	m := RestcommMetrics{}
	m.Date, _ = strconv.ParseUint(r.FormValue("date"), 10, 64)
	m.AppId = r.FormValue("appId")
	m.TaskId = r.FormValue("taskId")

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

	db.Set(key, value, h.Period)

	fmt.Fprintf(w, value)
}

func (h *RestcommAppHandler) avgStat() (map[string]*RestcommAvgMetrics, []interface{}) {

	stats := make(map[string]*RestcommAvgMetrics)

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
		var stat *RestcommAvgMetrics
		stat = stats[m.AppId]
		stat.Count++
		stat.LiveCalls += m.LiveCalls

		stat.LiveCallsAvg = stat.LiveCalls / stat.Count
	}

	return stats, metrics
}

func (h *RestcommAppHandler) checkState() {
	Trace.Println("checkState")

	stats, _ := h.avgStat()

	for k, v := range stats {
		callsLoad := v.LiveCallsAvg / h.MaxCalls

		Trace.Println("stateChecker: ", k, " -> calls =", callsLoad)
		if callsLoad > h.ScaleUp {
			Info.Println("\tscaleUp: ", k, " -> calls =", callsLoad)
			h.scaleUp(k)
		} else if callsLoad < h.ScaleDown {
			Info.Println("\tscaleDown: ", k, " -> calls =", callsLoad)
			h.scaleDown(k)
		}
	}
}

func (h *RestcommAppHandler) scaleUp(appId string) {
	h.scaleMesos("scale-up", appId)
}

func (h *RestcommAppHandler) scaleDown(appId string) {
	h.scaleMesos("scale-down", appId)
}

func (h *RestcommAppHandler) scaleMesos(action string, appId string) {
	Trace.Println("Scale restcomm app:", appId, " action = ", action)

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
	setBoolKey(delayKey, h.ScaleDelay)
}

func (h *RestcommAppHandler) getAppInstances(appId string) (int, error) {
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

func (h *RestcommAppHandler) scaleApp(instances int, appId string) {
	Info.Println("ScaleApp: ", appId, " to", instances)

	url := "http://" + h.Host + "/v2/apps/" + appId
	Trace.Println("scale app", appId, " to", instances, " url =", url)
	jsonStr := fmt.Sprintf("{\"instances\": %d}", instances)

	req, err := http.NewRequest("PUT", url, bytes.NewBufferString(jsonStr))
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
