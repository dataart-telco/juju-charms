package main

import(
    "gopkg.in/redis.v3"
    "time"
    "log"
)


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

func NewDbClient(ip string)(db *redis.Client){
    db = redis.NewClient(&redis.Options{
        Addr:    ip,
        Password: "", // no password set
        DB:       0,  // use default DB
    })

    pong, err := db.Ping().Result()
    if err != nil {
        log.Println(pong, err)
    }
    return db
}


func resetDb(){
    log.Println("Reset database")
    removeKeys("*")
}

func removeKeys(pattern string){
    key := "metric:" + pattern
    log.Println("removeKeys for", key)

    db := NewDbClient(ipRedis)
    keys := db.Keys(key).Val()
    log.Println("removeKeys: count = ", len(keys))

    for _, key := range keys {
        db.Del(key)
    }
}

func setBoolKey(key string, expTime int){
    db := NewDbClient(ipRedis)
    db.Set(key, true, time.Duration(expTime) * time.Minute)
}

func isKey(key string) bool{
    db := NewDbClient(ipRedis)
    return db.Exists(key).Val()
}

