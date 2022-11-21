---
layout: post
title: 给梦梦的debug本子
description: 写给女朋友的debug方法,以及具体的案例分析. 希望对大家也有帮助
categories:
- 技术
tags:
- go
---

debug的关键:

* 最好的方法是 "治未病"-- 尽量减少自己写的程序出 bug, 在写代码前, 理解一切: 语言的 API, 项目的上下文, 各种知识以及原理.  难道有一丝不清楚的代码你敢写吗?
* 根据现象与已有的知识，逻辑推理出可能的问题，再进行下一步；而不是一开始就把所有现象试出来
* 理解问题, 有报错信息的, 一定要把报错信息一字不漏的读完, 思考为什么会出错, 想出解决办法.
 而不是不管三七二十一到 Google 上搜索.
* 其次是, 永远保持耐心, 相信自己能解决问题

也许以上的道看似很千篇一律, 等你身经百战时, 自然会理解其中的道理.

以下是具体的方法:

1. 复制/提炼关键词，比如把个人项目的名字，个人的变量名这些网上不可能有人跟你一样的东西都删除掉，到网上搜索;

2. 尽可能利用二分法打印，确定程序出错的部位，具体哪一个语句;

3. 获取出错位置的上下文，比如变量的内容，出现什么错, 函数调用栈是怎么样;

4. 以上办法都没有帮助，就自己尝试改变变量内容，尝试复现错误或者避免错误发生，由此看看有没有启发;

5. 如果没法定位出错内容，就使用注释，看最小程序能运行的部分代码是什么，多一行就错的话，错的就是那个部分;

6. 对付疑似多线程死锁的 bug, strace 是一个神器-- 它可以把你在运行中的程序所调用的 linux 内核函数过程都打印出来: 这意味着, 你可以通过这些调用来确认它的状态;

7. 实在想不到，只有先搁置，或者自己试图用文字描述错误;

8. 文字描述完还是没有灵感，就问别人和 stackoverflow 吧

---
    

###复制/提炼关键词

```
(pq: duplicate key value violates unique constraint "users_email")```像这样一条报错信息，明显users_email是我自己的变量名，而pq则是psql数据库，括号doesn't help, 所以只需要查```pq: duplicate key value violates unique constraint
```


###硬编码

把函数或者一些变量硬编码(写死了它的值而不是赋值进去), 对比一下与原来结果

```
db, err := gorm.Open("postgres", "host=localhost user=yonghao dbname=backend sslmode=disable password=") 
```
，就可以连接数据库. 而 

```
db, err = gorm.Open("postgres", fmt.Sprintf("host=%s user=%s dbname=%s sslmode=disable password=%s",
			info.Host,
			info.Username,
			info.DBName,
			info.Password,
		)) 
```

则是去连接username而不是dbname的

成功时打印的信息

> [Warn] 2016/08/20 11:56:08 psql.go:30: success to connect database <nil> details:  host=localhost user=yonghao password= dbname=backend sslmode=disable

失败时打印的：
> reading config from: /etc/backend/config.json
[ERROR] 2016/08/20 11:51:19 psql.go:36: Failed to connect database pq: database "yonghao" does not exist details:  host=localhost user=yonghao password= dbname=backend sslmode=disable

后来对比一下硬编码与Sprintf的区别，便发现格式不太一样，心想会不会是格式的问题，便把硬编码的密码字段移到最后，最后发现了可以成功。再把硬编码里的密码字段移到前面，发现同样不行。
于是便确定了是问题是密码字段在中间，因为密码为空，便变成了这样```password=dbname=backend```，psql无法识别特殊字段，而放在最后没有任何东西才真正为空。

###硬编码

---
    

SQL查询语句无法找到内容，明明数据库里有记录，在数据库里执行没有问题。
再三检查SQL语句没有问题，到另外一个数据库里，复制一个查询的key到语句中硬编码可行，可是明明另外一个数据库与我的测试无关。
观察打印出来的信息, 最后发现是两个数据库配置不一样了。

---
    
###跟踪定位
根据出错信息, 一层层的跟踪定位出错的函数, 打印查看关键变量的值.

```
func GetAllTrustUsersBySN(sn string) ([]domain.TrustUser, error) {
	db := client.NewConn()
	var trustUsers []domain.TrustUser
	if err := db.Raw("select t.*, u.nickname from users u inner join robottrustuser t on u.userhash=t.userhash where t.robot_sn = ? order by t.tid", sn).Find(&trustUsers).Error; err != nil {
		return nil, err
	}
```

程序运行时crashed，利用报错时的堆栈信息（就是一层层的函数调用里，找最早自己写的函数），定位到以上函数，知道里面的db为空。
db为空，查看```client.NewConn()```，发现NewConn是系统函数应该没有问题，可能就是在client身上。client是全局变量， 在另外一个地方（父模块）里调用了

```
var client *psql.Client

func Init(c *psql.Client) {
	client = c
}
```

把初始化放到子模块里，捣弄一下，就可以了。
明显原因是只是启动子模块，并不会调用子模块的初始化，所以需要子模块特别初始化。

---

###怀疑不了解的API
遇到了不一样的情况, 对比一下同类的区别, 去调查自己不了解的API--永远要熟悉 API 才调用

我需要下载把数据写入到新文件里，但是发现创建文件是可以下载的，但是打开一个已经下载到一半的文件，并不能下载下来，文件大小一直都没有变化。在确认其他都没有问题的情况下， 我把错误信息打印出来了，发现是invalid argument。上网搜索信息无果，便对比一下

```
out, err = os.Open(filepath)
```

跟

```
out, err = os.Create(filepath)
```
创建跟打开的区别。
在我的代码里，没有区别。但是go语言的实现是如何呢？

```
func Open(name string) (*File, error) {
	return OpenFile(name, O_RDONLY, 0)
}
//以上是open的，下面试create的

// Create creates the named file with mode 0666 (before umask), truncating
// it if it already exists. If successful, methods on the returned
// File can be used for I/O; the associated file descriptor has mode
// O_RDWR.
// If there is an error, it will be of type *PathError.
func Create(name string) (*File, error) {
	return OpenFile(name, O_RDWR|O_CREATE|O_TRUNC, 0666)
}
```
没想到，两者都是调用OpenFile函数，但是权限不一样而已。因为我需要写入到文件里，而open只是用只读的方式打开了文件，所以便无法下载。

###改bug：
只需要把Create的所调用的OpenFile，改一下参数，不创建新文件，不清空文件，可读可写就行了。
	```		out, err = os.OpenFile(filepath, os.O_RDWR, 0666) ```


