---
layout: post
title: 从限流谈到伪造 IP nginx remote_addr
description: 
categories:
- 技术
tags:
- go
---

## 从限流谈到伪造 IP（nginx remote_addr）

#### remote_addr

很多流量大的网站会限流，比如一秒 1000 次访问即视为非法，会阻止 10 分钟的访问。

通常简单的做法，就是通过 nginx 时，nginx 设置

```
    proxy_set_header X-Real-IP $remote_addr;
```

nginx的 `$remote_addr`代表客户端的访问 ip，把它设到 http 请求的头部X-Real-IP；然后程序取出并存入数据库，统计访问次数。

`remote_addr` 基本上不能被伪造，因为是直接从 TCP 连接信息中获取的，也就是 `netstat` 的`Foreign Address`那栏。

你想想， 客户端A 与 B服务器建立 TCP 连接，是不是 B 肯定知道 A的公网地址是什么呢，除非客户端 A 是经过了一个代理服务器 Z， 那么就是 A -> Z -> B, 服务器 B 拿到的只能是 Z 的 ip 地址了，但这不意味就是伪造 ip，限流依然有效。



#### nginx 转发

上述应对外网访问，没有任何问题。假如公司内部需要测试，不停的访问服务器上的程序时，并且经过负载均衡或者 nginx 转发时，也就是 `client -> nginx1 -> nginx2 -> server`, `remote_addr` 就变成了nginx2 的内网地址了。

因此，需要在 `nginx1`处， e client 的 `remote_addr`， 再传给 `nginx2`，server 再取出。

示例：

```
   proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```

`$proxy_add_x_forwarded_for` 把 `$remote_addr` 加到 `X-Forwarded-For` 头部后面；最后设在 my_ips



> 如果是需要做 ip 统计，地理信息获取，天气定位等，需要常用的另一个 http 头部， `X-Forwarded-For ` 来做处理。通过名字就知道，X-Forwarded-For 是一个 HTTP 扩展头部。HTTP/1.1（RFC 2616）协议并没有对它的定义，它最开始是由 Squid 这个缓存代理软件引入，用来表示 HTTP 请求端真实 IP。如今它已经成为事实上的标准，被各大 HTTP 代理、负载均衡等转发服务广泛使用，并被写入 [RFC 7239](http://tools.ietf.org/html/rfc7239)（Forwarded HTTP Extension）标准之中。[1]

####  

然后my_ips 就代表了请求从 client 到 server 的完整ip路径， 只要由后往前推，直到 找到 外网的 ip，就证明这就是 client 的真正 ip。

```python
     bb_real_ip = request.environ.get('my_ips')
     bb_real_ip = bb_real_ip.replace(" ", "").split(',')
     for ip in reversed(bb_real_ip):
         if not is_private(ip):
             return ip

     # 不可能出现这种情况, 除非 LBS/nginx 没有设$proxy_add_x_forwarded_for
     return request.environ.get('REMOTE_ADDR')
```



这样取到的也是真实的 ip 地址，但有一个问题，假如 client 跟其他很多 client 通过同一个出口出来，共享一个外网 ip，那么如何获取它的 ip 呢？ 

这个情况下，限流一样可以生效，最多就是稍微误杀下无辜，影响不大。



#### 伪造 ip（也就是remote_addr）

那么，有办法伪造 `remote_addr`吗？ 其实本质就是，TCP 连接中，有办法伪造 ip 信息吗？

请看如何用hping3 工具发出伪装 ip 的包到 google.com：

```bash
$ sudo apt-get install hping3
$ sudo hping3 --icmp --spoof 6.6.6.6 baidu.com
HPING baidu.com (eth0 220.181.57.216): icmp mode set, 28 headers + 0 data bytes
```

另一个控制台抓icmp包：

```bash
$ sudo tcpdump -i eth0 'icmp'
21:24:58.562844 IP 6.6.6.6 > 220.181.57.216: ICMP echo request, id 11035, seq 5120, length 8
```

可以看到， 我们成功的伪装成 `6.6.6.6` 并向 baidu.com 发出了ping（也就是 ICMP 包），不过由于我们的 IP实质上并不是`6.6.6.6`，所以收不到 baidu.com 发往 它的 ICMP 包。

模拟的原理是，自己重新实现系统的 tcp （ICMP）协议栈，然后 自己改变自己的 ip。

值得一提的八卦是， hping 的作者是Salvatore Sanfilippo，同时他也是 redis 的作者。



试想一下，可以通过这个办法来做借刀杀人——伪造一个 ip（如`4.4.4.4`），大量发包给第三方（如 Google），然后第三方返回 TCP reset 或者 ICMP unreachable 给 你伪造的 ip(`4.4.4.4`), 这样就可以借 Google 来 ddos `4.4.4.4`了。[2]

但是现在运营商的路由器都部署了 uRPF，可以根据你发过来的源 ip 检测是否在路由表中，不在就拒绝掉此请求。



[1]: https://imququ.com/post/x-forwarded-for-header-in-http.html
[2]: https://serverfault.com/questions/90725/are-ip-addresses-trivial-to-forge?newreg=bc696301ccfa472da87c4913c7d117e9

