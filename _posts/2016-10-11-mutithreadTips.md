---
layout: post
title: 写多线程的小技巧
description: 多线程坑特别多,希望以下的小技巧能够帮你减轻负担
categories:
- 技术
tags:
- go
---

1. 可以使用golang的[race-detector](https://blog.golang.org/race-detector)检查资源冲突, 但最重要还是全局考虑资源分配问题.

2. 在debug多线程时,发现一个自己锁自己的bug.

```
func (p *RemoteConnPool) CloseMindsockConn(conn *Conn) error {
	p.mutex.RLock()
	defer p.mutex.RUnlock()
	for _, c := range p.Conns {
		if c.MindConn() == conn {
			p.Close(c)
		}
	}
	return nil
}

func (p *RemoteConnPool) Close(c RemoteConn) error {
	if c == nil {
		return nil
	}
	p.mutex.Lock()
	defer p.mutex.Unlock()
	if p.OnConnCloser != nil {
		p.OnConnClose(c.Id())
	}
	delete(p.Conns, c.Id())
	return c.Close()
}
```

在CloseMindsockConn里全局加了读锁遍历map，在==conn的条件时到Close函数里，Close函数里加了写锁删除map里的东西，结果就block了，死锁。

##解决方法:
不用全局读锁，在要使用close函数时把读锁去掉，用完又锁回来

即上述情况变成:

```
func (p *RemoteConnPool) CloseMindsockConn(conn *Conn) error {
	p.mutex.RLock()
	for _, c := range p.Conns {
		if c.MindConn() == conn {
			p.mutex.RUnlock()
			p.Close(c)
			p.mutex.RLock()
		}
	}
	p.mutex.RUnlock()
	return nil
}
```

---

朋友Googol Lee告诉我, 可以在写的时候有个约定,所有私有方法只考虑无竞争的情况,公开方法考虑如何在使用的时候消除竞争
基本的原则是分离责任，所有私有方法只考虑逻辑，不考虑并发，这样编写和测试都相对容易。公开函数考虑并发，实现的逻辑委托给对应的私有函数完成。
所以表现上，有可能会出现同时存在Close和close两个方法，其中公开的那个会保证外部调用时的锁维护，加锁后直接调用私有方法完成逻辑

在上面的情况下，就是close给CloseMindsockConn使用，不加锁也不会有冲突，也就不会自己锁自己
公开Close给外部使用，加锁，这样问题就好了

---

3. 
 
```
	for i := 0; i < connCount/2; i++ {
		go func() {
			conn := NewConn(&websocket.Conn{})
			mux.Lock()
			defer mux.Unlock()
			c := ConnPool.NewBaseRemoteConn(conn)
			remoteConns[c.id] = c
		}()
	}

	mux.RLock()
	defer mux.RUnlock()
	for ConnPool.ConnsCount() < connCount || len(remoteConns) < connCount {
		time.Sleep(time.Millisecond)
	}
```

此代码乍看没有问题,实际上由于开了很多线程都持有读锁改变remoteConns, 而下面for循环遍历读取remoteConns这个map的length,
所以条件不满足的时候,会一直循环,又由于持有读锁,所以上面的线程并不能写, 自然map也无法添加.
于是一直死循环.

##解决方法:

锁的范围太大了, 我们只是想对if里的条件加锁, 所以把条件抽象成函数,在里面加锁就好了.

```
	for isCreateConnsFinished() {
		time.Sleep(time.Millisecond)
	}

func isCreateConnsFinished() bool {
	mux.RLock()
	defer mux.RUnlock()
	return (ConnPool.ConnsCount() < connCount || len(remoteConns) < connCount)
}
```
