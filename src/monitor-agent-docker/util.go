package main

import(
    "bytes"
    "net/http"
    "net/url"
    "errors"
    "strconv"
)

func Post(url string, params url.Values) (int, error) {
    Trace.Println("Make POST req: url =", url)

    data := params.Encode()

    client := &http.Client{}
    r, _ := http.NewRequest(
        "POST",
        url,
        bytes.NewBufferString(data))

    r.Header.Add("Content-Length", strconv.Itoa(len(data)))
    r.Close = true
    resp, err := client.Do(r)
    if err != nil {
        return 0, err
    }
    defer resp.Body.Close()

    if resp.StatusCode != 200 {
        return resp.StatusCode, errors.New("Resp code is not 200 for " + url + "; status = " + resp.Status)
    }
    return 200, nil
}