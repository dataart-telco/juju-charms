package main

import (
	"encoding/json"
	"fmt"
	"time"
)

type StatsDump struct {
	Handlers []MetricsHandler
}

func (self *StatsDump) getJsonString() string {
	h := self.Handlers[0]
	stats, metrics := h.avgStat()

	jm1, _ := json.Marshal(metrics)
	jm2, _ := json.Marshal(stats)

	juju := fmt.Sprintf("{\"avg\": %s, \"data\": %s}", jm2, jm1)

	h2 := self.Handlers[1]
	stats2, metrics2 := h2.avgStat()
	jm21, _ := json.Marshal(metrics2)
	jm22, _ := json.Marshal(stats2)

	mesos := fmt.Sprintf("{\"avg\": %s, \"data\": %s}", jm22, jm21)

	now := time.Now()
	millis := now.UnixNano() / 1000000;

	return fmt.Sprintf("{\"@timestamp\":%d, \"timeFormatted\": \"%s\", \"charm\": %s, \"mesos:\": %s}",
		millis, now.Format("2006/01/02 15/04/05"),
		juju, mesos)
}
