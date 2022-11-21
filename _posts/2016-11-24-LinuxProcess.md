---
layout: post
title: 如何杀死孤儿进程们? how to kill orphan process?
description: 注意, 在Ubuntu系统里, 最新版已经是孤儿进程都是让init --user(session instance of upstart) 而不是PID为1的init进程托管了.虽然登录后此进程的PID就不变了，但是重新登录后又会变化.
categories:
- 技术
tags:
- go
---

孤儿进程: 当父进程被杀掉时, 所有的子进程都会变成孤儿进程, 被init进程(pid为1, 且第一个被kernel启动的进程)接管, 有些linux的实现会定期检查子进程, 如果他们退出了就清空他们的资源. 

注意, 在Ubuntu系统里, 最新版已经是孤儿进程都是让init --user(session instance of upstart) 而不是PID为1的init进程托管了.虽然登录后此进程的PID就不变了，但是重新登录后又会变化.

因此, 杀掉孤儿进程有以下办法:
1. 接收信号prctl, **在子进程的代码里**, 要求父进程退出后发送此信号到子进程, 子进程接收到此信号并处理
2. 查找所有PPID为1的进程, 并杀掉. 注意, 因为ubuntu里pid of init 可以帮你找到在ubuntu里变化的init进程id.

```
ps -elf | head -1; ps -elf | awk '{if ($3=="root" && $5 == 30483) {print $0}}' | awk '{print $4}' | sudo xargs kill -9
```
