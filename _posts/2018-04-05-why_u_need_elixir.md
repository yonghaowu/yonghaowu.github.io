---
layout: post
title: 为什么你一定需要学习 Elixir？
description: Elixir 是一门基于 erlang 开发的新语言，复用了 erlang 的虚拟机以及全部库
categories:
- 技术
tags:
- go
---

## 为什么你一定需要学习 Elixir？

Elixir 是一门基于 erlang 开发的新语言，复用了 erlang 的虚拟机以及全部库（站在已经生存了20多年巨人的肩膀上），定义了全新的语法以及构造了现代语言必不可少生态环境—包管理器，测试工具，formatter等。使用 Elixir，你可以方便的构建可用性高达99.9999以及天然分布式的程序（代码随手一写就是稳定的分布式），可以秒开成千上万 Elixir 里专属的进程（比起系统的进程更轻量级），处理高并发请求等等。



## Elixir 是怎么样的语言？

Elixir 是函数式语言，与 java，C++等过程式语言不通，没有变量。或者说，变量全都imutable(不可改变)。通过学习Elixir， 你可以学习多一种编程范式。

python 中你是这样子处理列表的：

```python
mylist = []
mylist.append('Google')
mylist.append('Facebook')
print mylist #结果是['Google', 'Facebook']
```



Elixir 中是这样子的：

```
myList = []
myList = List.insert_at(myList, 0, "Google")
myList = List.insert_at(myList, 1, "Facebook")
IO.inspect myList 
```

elixir 中这不是正常的写法，不过我只是用来介绍异同点。注意到，在面向对象思维的语言中，处理列表，是 用对象的方法，`mylist.append:` 对象.动作来处理； 而函数式因为变量是不可变的，是要  List.append(mylist, xx), 对象模块.动作(哪个对象)来处理，同时会返回修改后的新对象。

数据不可变，好处就是在高并发中，并不会因为状态多且不断变化，引致debug 异常困难——本来人的大脑就不适应多线程。



不可变，就意味着 for 与 while循环用不了，因为不存在变量 不断 变化，达到某值就中止循环~因此，你只能用递归来实现 while。

但是不怕，Elixir 提供了强大无比的抽象， `each` 函数，`map` 函数，`reduce` 函数，`all?`函数（判断列表所有值是否满足此条件），`group` 函数（类似数据库的 group） 等等，只有你想不到。相比之下，golang 真的是乏善可陈。



## 管道

是的，类似 linux 的管道 `|`，把处理结果传递给下一个函数。

```
1..100
|> Enum.map(fn x-> x+1 end)
|> Enum.filter(fn x-> rem(x, 2)==0 end)
|> Enum.filter(fn x-> rem(x, 3)==0 end)
|> Enum.filter(fn x-> rem(x, 5)==0 end)
|> IO.inspect
```



与以下的  代码相比，python是否相形见绌？

```
numbers = range(1, 100)
numbers = map( (lambda x: x+1), numbers )
numbers = filter( (lambda x: x%2 == 0), numbers )
numbers = filter( (lambda x: x%3 == 0), numbers )
numbers = filter( (lambda x: x%5 == 0), numbers )
print(numbers)
```



再来一个例子，来自Dave Long 的博客 [Playing with Elixir Pipes](https://davejlong.com/2017/01/27/playing-with-elixir-pipes/) ：

代码的作用是：取出请求的头部`x-twilio-signature` 签名，并且校验是否有效。

没有管道时，代码是这样子的：

```
signature = List.first(get_req_header(conn, "x-twilio-signature"))  
is_valid = Validator.validate(url_from_conn(conn), conn.params, signature)  
if is_valid do  
  conn
else  
  halt(send_resp(conn, 401, "Not authorized"))
end
```

加上管道：

```
signature = conn  
            |> get_req_header("x-twilio-signature")
            |> List.first
if conn  
   |> url_from_conn
   |> Validator.validate(conn.params, signature)
do  
  conn
else  
  conn |> send_resp(401, "Not authorized") |> halt
end  
```

逻辑就非常清晰了。还可以这样子写：

```
signature = conn  
            |> get_req_header("x-twilio-signature")
            |> List.first
conn  
|> url_from_conn
|> Validator.validate(conn.params, signature)
|> if(do: conn, else: conn |> send_resp(401, "Not authorized") |> halt)
```



## 进程 Actor Model

#### 轻量级的进程

在 Elixir 里，Elixir进程（以下简称进程，与系统进程区分开）是轻量级的进程，与操作系统的概念相差不多，只不过 Elixir 进程运行在虚拟机中。那为什么 Elixir 进程更快呢？

- Erlang 进程的堆栈是动态分配、随使用增长的，新建一个 Erlang 进程的开销远比系统进程 / 线程小得多，开销就像在 OO 语言中建立一个新对象般简单。
- 普通进程 / 线程的内存管理是基于页的，而页对于一个函数 + 一点点零碎来说都太大了。而实际中 OS 分配给普通进程的初始栈可以达到 Megabytes 级别。
- Erlang 进程之间是隔离的，没有共享状态，所有的消息都是异步的，不会继承大量的已有状态。
- Erlang 进程的调度是在 Erlang VM 内发生的，跟 OS 层没啥关系，无需普通进程 / 线程切换时的各种开销
- Erlang 进程的切换是一种类似直接 “跳转” 的方式，以 O(1) 复杂度实现。Erlang 调度器会管理这些切换，大概只需要几十个指令和数十纳秒的时间。普通线程的切换会需要数百上前纳秒，OS 调度器的运作复杂度可能是 O(logn) 或者 O(log(logn))。如果有上万个线程，这个时间将会大幅提升。[来自知乎](https://www.zhihu.com/question/23250024)

#### 像指挥交响乐队一样，指挥你的 Elixir 进程

对于Elixir 进程，你可以方便的用一个进程（supervisor）去管理子进程，supervisor会根据你设定的策略，来处理意外挂掉的子进程（这种情况不多的是，错误处理稍微做不好就会挂） ， 策略有：

- one_for_one：只重启挂掉的子进程
- one_for_all：有一个子进程挂了，重启所有子进程
- rest_for_one：在该挂掉的子进程 创建时间之后创建的子进程都会重启。

老夫敲代码就是一把梭！可不，只要重启就行。

实质上，这是有论文支持的: 在复杂的产品系统中，几乎所有的故障和错误都是暂态的，对某个操作进行重试是一种不错地解决问题方法——[Jim Gray的论文](http://mononcqc.tumblr.com/post/35165909365/why-do-computers-stop)中指出，使用这种方法处理暂态故障，系统的平均故障间隔时间(MTBF)提升了 4 倍。



因此，你就可以创建一课监控树，根节点就是啥事都不做，只负责监控的进程。其他都是它的子进程，如果不是 coredump（几乎不发生），那么根节点就不可能会挂；因此其他子进程就会正确的被处理。

当然，这有前提： 5 秒内重启超于 3 次，就会不再重启，让进程挂掉。为什么呢？因为重启是为了让进程回到当初启动时的稳定态，既然稳定态都不稳定了，重复做重启是没有意义的，这时迫切需要人来处理。



#### 方便的通信

一切皆消息。

进程间通信，就像微风一样自然。你所监管的进程而来的信息，调用的库的消息，全部都可以自己来 handle 并作相应处理。甚至还有抽象好的 GenServer 来让你专门处理消息与状态逻辑。

定时器？不需要的，我们甚至可以自己发送消息来实现更好的定时器：

`Process.send_after` 会在 xx 秒后发消息到指定的进程，通过这个功能，不断往自己发消息，从而实现定时器的功能。请看实现：

```
defmodule Periodically do
  require Logger
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    schedule_work(:do_some_work)
    {:ok, state}
  end

  def handle_info(:do_some_work, state) do
    doing_now()
    schedule_work(:do_some_work)
    {:noreply, state}
  end

  defp schedule_work(update_type) do
    Process.send_after(self(), update_type, 30*1000)
  end
end
```



相较于 setTimeOut 之类的，好处是什么？

Elixir 自带工具，可以查看所有进程的状态并管理，上面把`Periodically`作为一个进程启动起来了，自然可以管理他：P



## 模式匹配与宏

这个相较于平常我们的赋值语言比较新颖，介绍的篇幅过长。

请看http://szpzs.oschina.io/2017/01/30/elixir-getting-started-pattern-matching/ 以及https://elixir-lang.org/getting-started/pattern-matching.html



通过模式匹配，我们可以避免 if else 的嵌套地狱；可以利用语言自己的匹配来做 搜索，

宏可以让你实现自定义的 DSL（当然太强大的功能自然导致滥用出 bug），可以屏蔽掉很多不优雅的细节。



以上就是 Elixir 的简单介绍，建议诸位学习一下 Elixir，洗刷一下自己的 OO 以及过程式编程思维。
