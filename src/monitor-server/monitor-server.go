package main

import(
    "net/http"
    "encoding/json"
    "flag"
    "fmt"
    "strconv"
    "os/exec"
    "time"
    "log"
)

type Metrics struct {
    Date uint64
    CpuLoad1 int
    CpuLoad5 int
    Mem int 
    AppId string
    MachineId string
}

type Stat struct {
    MemSum int
    CpuLoad1 int
    CpuLoad5 int
    Count int

    MemAvg int
    CpuLoad1Avg int
    CpuLoad5Avg int
}

type HttpHandler func(http.ResponseWriter, *http.Request)

var pages map[string]HttpHandler

var ipRedis string
var cliDir string

var timeFrame int
var scaleDelay int

func stateChecker(){
    log.Println("stateChecker");

    stats, _ := avgStat()

    for k, v := range stats{
        period := v.CpuLoad1Avg
        if timeFrame > 1 {
            period = v.CpuLoad5Avg
        }   
              
        log.Println("stateChecker: ", k, " -> cpu =", period, "; mem =", v.MemAvg);
        if period > 70 {
            log.Println("\tscaleUp: ", k, " -> cpu =", period, "; mem =", v.MemAvg);
            scaleUp(k)
        } else if period < 10{
            log.Println("\tscaleDown: ", k, " -> cpu =", period, "; mem =", v.MemAvg);
            scaleDown(k)
        }
    }
}

func scaleUp(service string){
    scaleJuju("add-unit", service)
}

func scaleDown(service string){
    scaleJuju("scale-down", service)
}

func scaleJuju(action string, service string){
    delayKey := action + ":" + service
    if isKey(delayKey) {
        log.Println("ignore service scale")
        return;
    }

    log.Println("scaleJuju -> ", service, " -> action =", action);
    out , _ := exec.Command(cliDir + "/jujuapicli", "-c", cliDir + "/.jujuapi.yaml", action, service).Output()
    log.Println("<-", string(out));

    removeKeys(service + ":*")  
    setBoolKey(delayKey, scaleDelay)
}

func avgStat() (map[string]*Stat, []Metrics) {

    stats := make(map[string]*Stat)

    db := NewDbClient(ipRedis)

    keys := db.Keys("metric:*").Val()
    metrics := make([]Metrics, len(keys))

    for i, key := range keys {
        val := db.Get(key).Val()
        m := Metrics{}
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
        stat.CpuLoad1 += m.CpuLoad1
        stat.CpuLoad5 += m.CpuLoad5
        stat.MemSum += m.Mem
        stat.Count ++

        stat.CpuLoad1Avg = stat.CpuLoad1 / stat.Count
        stat.CpuLoad5Avg = stat.CpuLoad5 / stat.Count
        stat.MemAvg = stat.MemSum / stat.Count
    }
    
    return stats, metrics
}

func handleGet(w http.ResponseWriter, r *http.Request){
    w.Header().Set("Content-Type", "application/json")

    log.Println("\thandleGet")

    stats, metrics := avgStat()

    jm1, _ := json.Marshal(metrics);
    jm2, _ := json.Marshal(stats);
    
    fmt.Fprintf(w, "{\"avg\": %s, \"data\": %s}", jm2, jm1)
    
}

func handleMetrics(w http.ResponseWriter, r *http.Request){
    m := Metrics{}
    m.Date, _ = strconv.ParseUint(r.FormValue("date"), 10, 64);

    m.CpuLoad1, _ = strconv.Atoi(r.FormValue("cpuLoad1"))
    m.CpuLoad5, _ = strconv.Atoi(r.FormValue("cpuLoad5"))
    m.Mem, _  = strconv.Atoi(r.FormValue("mem"))
    m.AppId = r.FormValue("appId")
    m.MachineId = r.FormValue("machineId")

    bytes, _ := json.Marshal(&m)
    value := string(bytes)

    db := NewDbClient(ipRedis)
    key := "metric:" + m.AppId + ":" + m.MachineId;// + ":" + strconv.FormatUint(m.Date, 10);

    log.Println("Add stat for", key)

    db.Set(key, value, 5 * time.Minute)

    fmt.Fprintf(w, value)
}

func initHandlers() {
    pages = make(map[string]HttpHandler)
    pages["/"] = handleGet
    pages["/metrics"] = handleMetrics
}

func httpHandlerPlay(w http.ResponseWriter, r *http.Request){
    log.Println("\t<- http request -", r.URL.Path)
    
    f := pages[r.URL.Path]
    if f != nil {
        f(w, r)
        return
    }
    w.WriteHeader(http.StatusNotFound)
}

func start(port int) {
    log.Println("Start web server")
    initHandlers();
    http.HandleFunc("/", httpHandlerPlay)
    err := http.ListenAndServe(fmt.Sprintf(":%d", port), nil)
    if(err != nil){
        panic(err)
    }
}

func main(){
    host := flag.String("r", "127.0.0.1:6379", "Redis server");
    t := flag.Int("t", 5, "Avg period in minutes");
    port := flag.Int("p", 8080, "Bind port");
    cli := flag.String("cli-dir", "/var/lib/simple-monitor-service", "cli directory command");
    d := flag.Int("d", 10, "delay scale actions ");

    flag.Parse()

    log.Println("Start server with port =", *port, "| check period =", *t, "min(s) | redisHost =", *host, "| cli dir = ", *cli)

    cliDir = *cli
    ipRedis = *host
    timeFrame = *t
    scaleDelay = *d

    resetDb()
    
    //timeout in seconds
    schedule((*t * 60), stateChecker)

    start(*port)
}
