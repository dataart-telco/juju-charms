package main

import (
    "os"
    "os/signal"
    "syscall"
    "github.com/shirou/gopsutil/mem"
    "github.com/shirou/gopsutil/load"
    "log"
    "os/exec"
    "strconv"
    "time"
    "net/http"
    "net/url"
    "flag"
)

func WaitCtrlC(){
    var signal_channel chan os.Signal
    signal_channel = make(chan os.Signal, 2)
    signal.Notify(signal_channel, os.Interrupt, syscall.SIGTERM)
    <-signal_channel
}

func memoryInfo() int{
    v, _ := mem.VirtualMemory()
    return int(float64(v.Used) / float64(v.Total) * 100)
}

func cpuAvgInfo() (int, int){
    avg, _ := load.LoadAvg()
    return int(avg.Load1 * 100), int(avg.Load5 * 100)
}

func cmd(c string) string{
    out , err := exec.Command(c).Output()
    if err != nil {
        log.Fatal(err)
    }
    return string(out)
}

func schedule(step int, what func()){
    ticker := time.NewTicker(time.Duration(step) * time.Second)
    go func(){
        for {
            select {
                case <- ticker.C:
                    what()
            }
        }
    }()
}

func sendData(host string, appId string, cpuLoad1 int, cpuLoad5 int, mem int){
    pcName, _ := os.Hostname()

    resp, err := http.PostForm("http://" + host,
                    url.Values{ "date": {strconv.FormatInt(time.Now().UnixNano() / int64(time.Millisecond), 10)},
                                "cpuLoad1":  {strconv.Itoa(cpuLoad1)},
                                "cpuLoad5":  {strconv.Itoa(cpuLoad5)},
                                "mem":  {strconv.Itoa(mem)},
                                "appId": {appId},
                                "machineId": {pcName}})
    if( err != nil){
        log.Println("Error: ", err);
        return
    }
    log.Println("Send resp code:", resp.StatusCode)
}

func main(){
    host := flag.String("url", "127.0.0.1", "Monitor server");
    appId := flag.String("appId", "", "App id");

    flag.Parse()

    log.Println("Start agent with host =", *host, " and appId =", *appId)

    do := func(){
        load1, load5 := cpuAvgInfo()
        mem := memoryInfo()
        log.Println("CPU1: ", load1)
        log.Println("CPU5: ", load5)
        log.Println("Memory:", mem)

        sendData(*host, *appId, load1, load5, mem)
    }
    schedule(5, do)
    WaitCtrlC()
}
