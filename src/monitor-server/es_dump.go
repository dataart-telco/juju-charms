package main

import (
	"bytes"
	"net/http"
	"io/ioutil"
)

type EsDump struct {
	Dumper *StatsDump
	Host string
}

func (self *EsDump) createMapping(){
	url := "http://" + self.Host + "/monitor";

	mapping := "{\"mappings\":{\"monitor\":{\"properties\":{\"@timestamp\":{\"type\":\"date\",\"format\":\"epoch_millis\"},\"charm\":{\"properties\":{\"avg\":{\"properties\":{\"mesos-slave\":{\"properties\":{\"Count\":{\"type\":\"long\"},\"CpuLoad1\":{\"type\":\"long\"},\"CpuLoad1Avg\":{\"type\":\"long\"},\"CpuLoad5\":{\"type\":\"long\"},\"CpuLoad5Avg\":{\"type\":\"long\"},\"MemAvg\":{\"type\":\"long\"},\"MemSum\":{\"type\":\"long\"}}}}},\"data\":{\"properties\":{\"AppId\":{\"type\":\"string\"},\"CpuLoad1\":{\"type\":\"long\"},\"CpuLoad5\":{\"type\":\"long\"},\"Date\":{\"type\":\"long\"},\"MachineId\":{\"type\":\"string\"},\"Mem\":{\"type\":\"long\"}}}}},\"mesos:\":{\"properties\":{\"avg\":{\"type\":\"object\"}}},\"timeFormatted\":{\"type\":\"string\"}}}}}"

	buf := bytes.NewBufferString(mapping)
	resp, err := http.Post(url, "application/json", buf)
	if err != nil {
		return
	}
	resp.Body.Close()
}

func (self *EsDump) sendData() {
	stats := self.Dumper.getJsonString()

	url := "http://" + self.Host + "/monitor/monitor";

	Trace.Println("Try to send data to: ", url, " with ", stats)

	buf := bytes.NewBufferString(stats)
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
