package main

import (
	"encoding/json"
	"fmt"
)

type StatsDump struct {
	handlers []MetricsHandler
}

func (self *StatsDump) getJsonString() string {
	h := self.handlers[0]
	stats, metrics := h.avgStat()

	jm1, _ := json.Marshal(metrics)
	jm2, _ := json.Marshal(stats)

	juju := fmt.Sprintf("{\"avg\": %s, \"data\": %s}", jm2, jm1)

	h2 := self.handlers[1]
	stats2, metrics2 := h2.avgStat()
	jm21, _ := json.Marshal(metrics2)
	jm22, _ := json.Marshal(stats2)

	mesos := fmt.Sprintf("{\"avg\": %s, \"data\": %s}", jm22, jm21)

	return fmt.Sprintf("{\"charm\": %s, \"mesos:\": %s}", juju, mesos)
}
