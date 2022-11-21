---
layout: post
title: Google Japan第二次电面
description:  又特么跪了
categories:
- 技术
tags:
- go
---

## Google  Japan 第二次面试

面试官打来，寒暄了一两句，就说 should we start?

我以为像上次一样，直接一道 leetcode hard 难度拍过来，没想到竟然问基础知识！
http://yonghaowu.github.io//2016/10/25/GoogleJapanInterview/



1. ### Do u know **memory leak*?

>  c/c++, new/malloc forget to free memory delete

>  C++, smart pointer, RAIIwhen we don’t use that resources(memory), will free it automaticallyreference counter(tech)golang, `defer`

问内存泄漏，只有竟可能展示能力了(装逼), 说了常见的场景，C++智能指针，RAII，引用计数，甚至还说了 golang 的 defer



1. ### Do u know some methods to solve it?

>  valgrind

问我有没有在项目中解决过，只好说实习和参加 Wine 开源项目都没有遇到过，知道可以用 valgrind，只是在 demo 用过。  

1. ### buffer overflow?

>  array, char a[100]，boundary

> for(int i=0; i<=100; ++i) a[i] overflow

> strcpy,strncpy

> sequence

>  [0x1001, 0x1002, ..]

> [1, 2, 3, 4]

> a[4] visit another address 

> cause some problems, we  may modify other values, write protected area* 

> use buffer overflow, execute some code

缓冲区溢出，举了例子以及常见场景, 读写系统保护区呀， readOnly 部分，修改了其他东西



## 代码部分

```
(Coding) Implement a key value store with an expiration date.

example usage:
key=url
value=html source

void put(int key, int value) {
} 

int get(int key) {
}
```

一看， 特别简单，脑子进水了也能做那种。

但没有如此简单。



这个更偏向于跟他 clarify 这个题目，超多细节需要讨论的，因为他 put 函数原型都没有写对，过期不的字段都没有给。



首先我问了， 如何在 put 里判断过期？没有过期的判断字段。然后他就加上了：

> **void put(int key, int value, long durationMs) {**}
>
> **long getCurrentTimeMs();**

接着我问， 如果 get 时过期了怎么处理？他加上了

> **const int kNotFound = -99999;**

接着开始设计 map，询问后确定可以用 C++的 map。

使用 C++ unordered_map， 因为程序中并没有顺序问题。

```
struct valueWithExpirationDate {
	long expirationDate;
	unordered_map<int, int> hashMap;
} val;
```

随后发现问题，问道：是否需要一个全局 map？因为参数中没有； 答曰：是的；

于是改 struct

```
struct valueWithExpirationDate {
	long expirationDate;
	int  value;
} val;
unordered_map<int, struct valueWithExpirationDate> globalMap;
```

接着开始实现put

```
// put the same key twice? should we cover it? Overwrite
// One global map ?Yep.
// Check expireateion data overflow? long can not save such huge value. no
void put(int key, int value, long durationMs) {
	long expirationDate = getCurrentTimeMs()+ durationMs;
	struct valueWithExpirationDate val = {expirationDate, value};
	globalMap[key] = val;
}
```

写的时候确定：1.long存不下 overflow 需要考虑不 2. getCurrentTimeMs需要自己实现不 3. 重复存一个 key 怎么办； 答案在注释

边写边解释后写 get 函数：

```
int get(int key) {//if the value is expired?should we return the val? 
	if(!globalMap[key]) {
		return kNotFound;
	}
	//found
	if(globalMap[key].expirationDate < getCurrentTimeMs()) {
		return kNotFound;
	}
	
	return globalMap[key].value;
}
```

你们会发现，我并没有存指针而是整个结构体，写的时候我发现了，不过想着之后可以提出来，于是接着写下去了。

写完后问，有什么办法可以 improve 整个程序吗？

答道：用指针而不是存 struct，把写好的程序都改成用指针。

接着他指出，还有，你过期后。。我马上觉察，说：对，并没有删除过期的东西。

然后他写出了函数原型：

```
void cleanup() {
  // remove all expired keys
  //iterate all the members in map
}
```

我马上 clarify 说遍历所有 members，他说你有更好的办法吗？

我说可以对 expiration time 排序，每次 put 的时候clean up, 可以用 piority queue

他说可以，我问是先写 cleanup 代码，还是用priority queue优化代码, 他说『优化，I am sure you can write the code, I trust you]

举例子：

> **current : 1111// {12, 1023) (14, 1234) (14, 3333(**
>
> 每次put，就依次删除expiration time 小的（clean up) 
>
> 向他 clarify**put is seldomely than get called? => it is good to clean up while put \c**
>
> 如果调用 put 次数不够 get 多的话，意味着 put 之间间隔的时间很长，可以检查 clean up 并清除了

然后因为他沉默有点次数多， 我就问了他几次，要不要写代码了，还是上面那句 LOL



接着问我时间复杂度，分析 `put`

因为用piority queue, 每次put都要遍历一遍，所以需要 O(n), n 是 length of map

接着`get`

**// unorded_map(hash map), O(1) apply to put func also**

这里装逼有点忘形，要补充说 put 是 O(1)当没有用优先队列；

随后在上面补充：

**//quick sort, heapsort, mostly O(n logn), On^2 when uses cleanup()**

有点小小的搞混了是 put 的 cleanup用到了 piority  queue，不过没写代码，我跟面试官都有一点点混了 LOL。不过幸好大致意思我们都知道。



随后又是面试官的沉默。。

为了利用时间，我又不得不装逼了：说因为写 golang 比较多，所以刚刚没有用 Google C++ code styple  (XD)

> **google C++ sytle**
>
> _ namecapital name, sumOfAll instead of sum_of_all



------

接着就到， "I think our time is up"

我说了" thank you" 后，迷之画风，他就说"thanks， I think that's it"之类的，大有结束之势。。

这面试官怎么不套路了？我赶紧问， "could I ask you a few questions?"

于是问了的确是编码中有点疑惑的问题：

1. code review 是怎么做的
2. TDD，test 写吗，先写测试还是？

最后当然是最 xx 的问题， How is it working in google? 

```
code review, peer review
peer review may not strict enough

unit test every time?Is that test first?rule
How is it working in google? 
chrome, arictue
memory allocated, javascript -> C++, env open
GSoC work 
```

面试官变得有点话多的，的确很喜欢 Google，就说他是 做chrome 的，做内存分布啥的，js 转 C++等，

参加过 GSoC too，工作就像是在做开源项目一样，excited！

表示 awesome！GSoC 非常棒！

结束面试：P
全部时间刚刚好40分钟

---

后记：
时间复杂度分析我出现问题了， 对优先队列和堆不够熟悉。
堆排序，put复杂度是 O(n logn), get 是 O(1)
而优先队列在问题的场景下是用了堆实现的，所以put 是插入，复杂度为 O(logn)，并不是堆排序的排序复杂度。
