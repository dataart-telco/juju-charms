package main

import (
	"bytes"
	"net/http"
)

type EsDump struct {
	StatsDump
	Host string
}

func (self *EsDump) sendData() {
	stats := &self.StatsDump
	buf := bytes.NewBufferString(stats.getJsonString())
	resp, err := http.Post("http://"+self.Host+"/monitor/monitor", "application/json", buf)
	if err != nil {
		return
	}
	resp.Body.Close()
}
