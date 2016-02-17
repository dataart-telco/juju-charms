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

	mapping := "{\"mappings\":{\"monitor\":{\"properties\":{\"Timestamp\":{\"type\":\"date\",\"format\":\"epoch_millis\"},\"Source\":{\"type\":\"string\",\"index\":\"not_analyzed\"},\"CpuLoad1Avg\":{\"type\":\"int\"},\"CpuLoad5Avg\":{\"type\":\"int\"},\"MemAvg\":{\"type\":\"int\"}}}}}"

	buf := bytes.NewBufferString(mapping)
	resp, err := http.Post(url, "application/json", buf)
	if err != nil {
		return
	}
	resp.Body.Close()
}

func (self *EsDump) createMapping() {
	mappingHardware := "{\"mappings\":{\"hardware\":{\"_timestamp\":{\"enabled\":true}, \"properties\":{\"Source\":{\"type\":\"string\",\"index\":\"not_analyzed\"},\"CpuLoad1Avg\":{\"type\":\"int\"},\"CpuLoad5Avg\":{\"type\":\"int\"},\"MemAvg\":{\"type\":\"int\"}}}}}"
	self.createMappingV1(mappingHardware)

	mappingRestcomm := "{\"mappings\":{\"restcomm\":{\"_timestamp\":{\"enabled\":true}, \"properties\":{\"Source\":{\"type\":\"string\",\"index\":\"not_analyzed\"},\"LiveCallsAvg\":{\"type\":\"int\"}}}}}"
	self.createMappingV1(mappingRestcomm)
}

func (self *EsDump) createMappingV1(mapping string){
	url := "http://" + self.Host + "/monitor";

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
		mapping, data := self.convert(k, v, now)
		self.sendData2Server(mapping, data)
	}
}

func (self *EsDump) convert(source string, data interface{}, now int64) (string, interface{}) {
	switch v := data.(type) {
		case *Stat:
			return "hardware", HardwareAvgData{Source: source, Timestamp: now, CpuLoad1Avg: v.CpuLoad1Avg, CpuLoad5Avg: v.CpuLoad5Avg}
		case *RestcommAvgMetrics:
			return "restcomm", RestcommAvgData{Source: source, Timestamp: now, LiveCallsAvg: v.LiveCallsAvg}
		default:
			return "common", v
	}
}

func (self *EsDump) sendData2Server(mapping string, data interface{}) {

	url := "http://" + self.Host + "/monitor/" + mapping;

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
