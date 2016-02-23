package main

import (
    "bytes"
    "encoding/json"
    "errors"
    "fmt"
    "io/ioutil"
    "net/http"
)

type MarathonClient struct{
    Host string
    ScaleDelay int
}

func (h *MarathonClient) scaleUp(appId string) {
    h.scaleMesos("scale-up", appId)
}

func (h *MarathonClient) scaleDown(appId string) {
    h.scaleMesos("scale-down", appId)
}

func (h *MarathonClient) scaleMesos(action string, appId string) {
    Trace.Println("Scale mesos app:", appId, " action = ", action)

    delayKey := action + ":" + appId
    if isKey(delayKey) {
        Info.Println("ignore service scale, delay reason")
        return
    }

    instances, err := h.getAppInstances(appId)
    if err != nil {
        return
    }

    defer removeKeys(appId + ":")

    if "scale-down" == action {
        if instances == 1 {
            Trace.Println("Ignore scale down! instances count =", instances)
            return
        }
        instances--

    } else if "scale-up" == action {
        instances++
    }
    h.scaleApp(instances, appId)
    setBoolKey(delayKey, h.ScaleDelay)
}

func (h *MarathonClient) getAppInstances(appId string) (int, error) {
    url := "http://" + h.Host + "/v2/apps/" + appId

    Trace.Println("Get app state:", url)

    resp, err := http.Get(url)
    if err != nil {
        Warning.Println("can't load info for", appId)
        return 0, errors.New("load info for " + appId)
    }
    defer resp.Body.Close()
    body, err := ioutil.ReadAll(resp.Body)
    if err != nil {
        Warning.Println("Read body error", err)
        return 0, errors.New("read response body")
    }

    app := make(map[string]interface{})
    json.Unmarshal(body, &app)
    app = app["app"].(map[string]interface{})
    return int(app["instances"].(float64)), nil
}

func (h *MarathonClient) scaleApp(instances int, appId string) {
    Info.Println("ScaleApp: ", appId, " to", instances)

    url := "http://" + h.Host + "/v2/apps/" + appId
    Trace.Println("scale app", appId, " to", instances, " url =", url)
    jsonStr := fmt.Sprintf("{\"instances\": %d}", instances)

    req, err := http.NewRequest("PUT", url, bytes.NewBufferString(jsonStr))
    req.Header.Set("X-Custom-Header", "myvalue")
    req.Header.Set("Content-Type", "application/json")

    client := &http.Client{}
    resp, err := client.Do(req)
    if err != nil {
        Warning.Println("Send request error", err)
        return
    }
    defer resp.Body.Close()
    body, err := ioutil.ReadAll(resp.Body)
    if err != nil {
        Warning.Println("Read body error", err)
        return
    }
    Trace.Println("Update response", string(body))
}