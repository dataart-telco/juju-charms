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

type AvgData struct {
	Source string
	Timestamp int64
	CpuLoad1Avg int
	CpuLoad5Avg int
	MemAvg int
}

func (self *EsDump) createMapping(){
	url := "http://" + self.Host + "/monitor";

	mapping := "{\"mappings\":{\"monitor\":{\"properties\":{\"Timestamp\":{\"type\":\"date\",\"format\":\"epoch_millis\"},\"Source\":{\"type\":\"string\",\"index\":\"not_analyzed\"},\"CpuLoad1Avg\":{\"type\":\"long\"},\"CpuLoad5Avg\":{\"type\":\"long\"},\"MemAvg\":{\"type\":\"long\"}}}}}"

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

	avgMesosCluster, _ := self.Dumper.Handlers[0].avgStat()
	avgApps, _ := self.Dumper.Handlers[1].avgStat()

	self.sendStats(avgMesosCluster, millis)
	self.sendStats(avgApps, millis)

}

func (self *EsDump) sendStats(data map[string]*Stat, now int64) {
	for k, v := range data {
		avg := AvgData{Source: k, Timestamp: now, CpuLoad1Avg: v.CpuLoad1Avg, CpuLoad5Avg: v.CpuLoad5Avg}
		self.sendData2Server(&avg)
	}
}

func (self *EsDump) sendData2Server(data *AvgData) {

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
