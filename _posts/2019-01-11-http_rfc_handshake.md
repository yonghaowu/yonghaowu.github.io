---
layout: post
title: 三次握手的误解与错误类比(RFC解读)
description: 
categories:
- 技术
tags:
- go
---
## 三次握手的误解与错误类比(RFC解读)

![公众号](https://img-blog.csdnimg.cn/20210211125314723.jpg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hpb2hpb2h1,size_16,color_FFFFFF,t_70#pic_center)

关于TCP三次握手几乎是应届毕业生面试常见的问题了，然而网上还很多比比皆是的错误，以知乎 [TCP 为什么是三次握手，而不是两次或四次？](https://www.zhihu.com/question/24853633) 上的热门答案为例子，第一个3.6K 次赞同的类比就是错误的：

```
三次握手：
“喂，你听得到吗？”
“我听得到呀，你听得到我吗？”
“我能听到你，今天 balabala……”
```

同样这个107次赞同的类比也是错误的：

```
握手和敬军礼一样，源自「敌我双方互相确认对方手里没有武器、无恶意」的仪式。（虽然双方互相请求确认需要四步，但由于中间的确认和请求是由同一个人执行的，所以合并成了一步） 
正恩伸出手说：你看，我手里没有武器。（SYN） 
朗普看了看说：嗯，确实没有。（ACK）
于是也伸出手说：你看，我手里也没有武器。（SYN）
正恩看了看说：嗯，看来你确实有诚意。（ACK）
```



这两个类比就是想当然的错误，为什么会错误，看完全文相信你便了然于心。

另外还有一个就是在谢希仁著《计算机网络》第四版中，讲 “三次握手” 的目的是 “为了防止已失效的连接请求报文段突然又传送到了服务端，因而产生错误”，这个只能算是表因，并不涉及本质。

> 谢希仁版《计算机网络》中的例子是这样的，“已失效的连接请求报文段” 的产生在这样一种情况下：client 发出的第一个连接请求报文段并没有丢失，而是在某个网络结点长时间的滞留了，以致延误到连接释放以后的某个时间才到达 server。本来这是一个早已失效的报文段。但 server 收到此失效的连接请求报文段后，就误认为是 client 再次发出的一个新的连接请求。于是就向 client 发出确认报文段，同意建立连接。假设不采用 “三次握手”，那么只要 server 发出确认，新的连接就建立了。由于现在 client 并没有发出建立连接的请求，因此不会理睬 server 的确认，也不会向 server 发送数据。但 server 却以为新的运输连接已经建立，并一直等待 client 发来数据。这样，server 的很多资源就白白浪费掉了。采用 “三次握手” 的办法可以防止上述现象发生。例如刚才那种情况，client 不会向 server 的确认发出确认。server 由于收不到确认，就知道 client 并没有要求建立连接。”



如果你细读[RFC793](https://www.ietf.org/rfc/rfc793.txt)，也就是 TCP 的协议 RFC，你就会发现里面就讲到了为什么三次握手是必须的——TCP 需要 seq 序列号来做可靠重传或接收，而避免连接复用时无法分辨出 seq 是延迟或者是旧链接的 seq，因此需要三次握手来约定确定双方的 ISN（初始 seq 序列号）。

下面给出详细的 RFC 解读说明：（数据分组称为分段（Segment），国内通常用包来称呼）

------

我们首先要知道到一点就是， TCP 的可靠连接是靠  seq（ sequence numbers 序列号）来达成的。

> A fundamental notion in the design is that every octet of data sent
> over a TCP connection has a sequence number.  Since every octet is
> sequenced, each of them can be acknowledged.  
> The acknowledgment mechanism employed is cumulative so that an acknowledgment of sequence
> number X indicates that all octets up to but not including X have been
> received. 

TCP 设计中一个基本设定就是，通过TCP 连接发送的每一个包，都有一个sequence number。而因为每个包都是有序列号的，所以都能被确认收到这些包。

确认机制是累计的，所以一个对sequence number X 的确认，意味着 X 序列号之前(不包括 X) 包都是被确认接收到的。



> The protocol places no restriction on a particular connection being
>   used over and over again.  
>
> The problem that arises from this is  -- "how does the TCP identify duplicate segments from previous
> incarnations of the connection?"  This problem becomes apparent if the
> connection is being opened and closed in quick succession, or if the
> connection breaks with loss of memory and is then reestablished.

TCP 协议是不限制一个特定的连接（两端 socket 一样）被重复使用的。

所以这样就有一个问题：这条连接突然断开重连后，TCP 怎么样识别之前旧链接重发的包？——这就需要独一无二的  ISN（初始序列号）机制。



> When new connections are created,
>   an initial sequence number (ISN) generator is employed which selects a
>   new 32 bit ISN.  The generator is bound to a (possibly fictitious) 32
>   bit clock whose low order bit is incremented roughly every 4
>   microseconds.  Thus, the ISN cycles approximately every 4.55 hours.
>   Since we assume that segments will stay in the network no more than
>   the Maximum Segment Lifetime (MSL) and that the MSL is less than 4.55
>   hours we can reasonably assume that ISN's will be unique.

当一个新连接建立时，`初始序列号（ initial sequence number ISN）生成器`会生成一个新的32位的 ISN。

这个生成器会用一个32位长的时钟，差不多`4µs` 增长一次，因此 ISN 会在大约 4.55 小时循环一次

（`2^32`位的计数器，需要`2^32*4 µs`才能自增完，除以1小时共有多少µs便可算出`2^32*4 /(1*60*60*1000*1000)=4.772185884` ）

而一个段在网络中并不会比最大分段寿命（Maximum Segment Lifetime (MSL) ，默认使用2分钟）长，MSL 比4.55小时要短，所以我们可以认为 ISN 会是唯一的。



发送方与接收方都会有自己的 ISN （下面的例子中就是 X 与 Y）来做双方互发通信，具体的描述如下：

> 1) A --> B  SYN my sequence number is X
> 2) A <-- B  ACK your sequence number is X
> 3) A <-- B  SYN my sequence number is Y
> 4) A --> B  ACK your sequence number is Y

2与3都是 B 发送给 A，因此可以合并在一起，因此成为`three way (or three message) handshake`（其实翻译为三步握手，或者是三次通信握手更为准确）

因此最终可以得出，三次握手是必须的：

> A three way handshake is necessary because sequence numbers are not
> tied to a global clock in the network, and TCPs may have different
> mechanisms for picking the ISN's. The receiver of the first SYN has
> no way of knowing whether the segment was an old delayed one or not,
> unless it remembers the last sequence number used on the connection
> (which is not always possible), and so it must ask the sender to
> verify this SYN. The three way handshake and the advantages of a
> clock-driven scheme are discussed in [3].

三次握手（A three way handshake）是必须的， 因为 sequence numbers（序列号）没有绑定到整个网络的全局时钟（全部统一使用一个时钟，就可以确定这个包是不是延迟到的）以及 TCPs 可能有不同的机制来选择 ISN（初始序列号）。

接收方接收到第一个 SYN 时，没有办法知道这个 SYN 是是否延迟了很久了，除非他有办法记住在这条连接中，最后接收到的那个sequence numbers（然而这不总是可行的）。

这句话的意思是：一个 seq 过来了，跟现在记住的 seq 不一样，我怎么知道他是上条延迟的，还是上上条延迟的呢？

所以，接收方一定需要跟发送方确认 SYN。



假设不确认 SYN 中的 SEQ，那么就只有：

> 1) A --> B  SYN my sequence number is X
> 2) A <-- B  ACK your sequence number is X  SYN my sequence number is Y

只有B确认了收到了 A 的 SEQ， A 无法确认收到  B 的。也就是说，只有 A 发送给 B 的包都是可靠的， 而 B 发送给 A 的则不是，所以这不是可靠的连接。这种情况如果只需要 A 发送给 B ，B 无需回应，则可以不做三次握手。





#### 三次握手详细过程

```
      TCP A                                                TCP B

  1.  CLOSED                                               LISTEN

  2.  SYN-SENT    --> <SEQ=100><CTL=SYN>               --> SYN-RECEIVED

  3.  ESTABLISHED <-- <SEQ=300><ACK=101><CTL=SYN,ACK>  <-- SYN-RECEIVED

  4.  ESTABLISHED --> <SEQ=101><ACK=301><CTL=ACK>       --> ESTABLISHED

  5.  ESTABLISHED --> <SEQ=101><ACK=301><CTL=ACK><DATA> --> ESTABLISHED

          Basic 3-Way Handshake for Connection Synchronization

                                Figure 7.
```



在上图

- 第二行中， A 发送了 SEQ 100，标志位是 SYN；
- 第三行，B 发回了 ACK 101 与 SEQ 300，标志位是 SYN 与 ACK（两个过程合并了）。注意，ACK 是101意味着，B 希望接收到 101序列号开始的数据段。
- 第四行，A 返回了空的数据，SEQ 101， ACK 301，标志位为 ACK。至此，双方的开始 SEQ （也就是 ISN）号100与300都被确认接收到了。
- 第五行，开始正式发送数据包，注意的是 ACK 依旧是第四行的301，因为没有需要 ACK 的 SYN 了（第四行已经 ACK 完）。
