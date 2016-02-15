package main

import (
	"encoding/json"
	"bytes"
	"net/http"
	"io/ioutil"
	"time"
)

type EsDump struct {
	Dumper *StatsDump
	Host string
}

type HardwareAvgData struct {
	Source string
	Timestamp int64
	CpuLoad1Avg int
	CpuLoad5Avg int
	MemAvg int
}

type RestcommAvgData struct {
	Source string
	Timestamp int64
	LiveCallsAvg int
}

func (self *EsDump) createMappingV2(){
	url := "http://" + self.Host + "/monitor";

	mapping := "{\"mappings\":{\"monitor\":{\"properties\":{\"Timestamp\":{\"type\":\"date\",\"format\":\"epoch_millis\"},\"Source\":{\"type\":\"string\",\"index\":\"not_analyzed\"},\"CpuLoad1Avg\":{\"type\":\"long\"},\"CpuLoad5Avg\":{\"type\":\"long\"},\"MemAvg\":{\"type\":\"long\"}}}}}"

	buf := bytes.NewBufferString(mapping)
	resp, err := http.Post(url, "application/json", buf)
	if err != nil {
		return
	}
	resp.Body.Close()
}

func (self *EsDump) createMappingV1(){
	url := "http://" + self.Host + "/monitor";

	mapping := "{\"mappings\":{\"monitor\":{\"_timestamp\":{\"enabled\":true}, \"properties\":{\"Source\":{\"type\":\"string\",\"index\":\"not_analyzed\"},\"CpuLoad1Avg\":{\"type\":\"long\"},\"CpuLoad5Avg\":{\"type\":\"long\"},\"MemAvg\":{\"type\":\"long\"}}}}}"

	buf := bytes.NewBufferString(mapping)
	resp, err := http.Post(url, "application/json", buf)
	if err != nil {
		return
	}
	resp.Body.Close()
}

func (self *EsDump) sendData() {

	now := time.Now()
	millis := now.UnixNano() / 1000000;

	for _, h := range self.Dumper.Handlers{
		data, _ := h.avgStat()
		self.sendStats(data, millis)		
	}
}

func (self *EsDump) sendStats(data map[string]interface{}, now int64) {
	for k, v := range data {
		self.sendData2Server(self.convert(k, v, now))
	}
}

func (self *EsDump) convert(source string, data interface{}, now int64) interface{} {
	switch v := data.(type) {
		case *Stat:
			return HardwareAvgData{Source: source, Timestamp: now, CpuLoad1Avg: v.CpuLoad1Avg, CpuLoad5Avg: v.CpuLoad5Avg}
		case *RestcommAvgMetrics:
			return RestcommAvgData{Source: source, Timestamp: now, LiveCallsAvg: v.LiveCallsAvg}
		default:
			return v
	}
}

func (self *EsDump) sendData2Server(data interface{}) {

	url := "http://" + self.Host + "/monitor/monitor";

	jsonData, _ := json.Marshal(&data)

	Trace.Println("Try to send data to: ", url, " with ", string(jsonData))
	buf := bytes.NewBuffer(jsonData)
	resp, err := http.Post(url, "application/json", buf)
	if err != nil {
		Warning.Println("can not send data", err)
		return
	}

	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		Warning.Println("Read body error", err)
		return
	}
	Trace.Println("response: ", string(body))
}
