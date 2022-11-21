---
layout: post
title: golang channel详解
description:  用了快一年的 golang 了,对 channel 实质应用还不多,理解不够透彻
categories:
- 技术
tags:
- go
---

1. 多线程的并发处理: 在有限时间内, 同时并发处理 n 个资源

```
    //from https://talks.golang.org/2012/concurrency.slide#47
    c := make(chan Result)
    go func() { c <- Web(query) } ()
    go func() { c <- Image(query) } ()
    go func() { c <- Video(query) } ()

    timeout := time.After(80 * time.Millisecond)
    for i := 0; i < 3; i++ {
        select {
        case result := <-c:
            results = append(results, result)
        case <-timeout:
            fmt.Println("timed out")
            return
        }
    }
    return
```

2. 利用 ticker 监控 

```
func monitorInstallProgress(s *InstalledSkill, c mindsocket.RemoteConn, body io.ReadCloser) {
	for {
		select {
		case <-s.passThru.ticker.C:
			if err := sendInstallProcess(s, c); err != nil {
				return
			}
		case <-s.passThru.quit:
			body.Close()
			loggers.Debug.Println("quit succeed")
			return
		}
	}
}
```

3. 待续..
