---
layout: post
title: 为什么free不像malloc一样需要长度参数吗?
description: 你想过为什么free不像malloc一样需要长度参数吗? 照理来说, malloc需要指定分配多少内存, free也应该要指定释放多少, 对吧?
categories:
- 技术
tags:
- C++
---

大家先看看下面的程序:

```
#include <stdio.h>
#include <stdlib.h>
int main(void)
{
    char* c = (char*)malloc(100);
    c[0] = 'w';
    c[1] = 'o';
    printf("%s\n", c);
    free(c+2);
    printf("%s\n", c);
    return 0;
}
```

申请了内存后, 使用了2个字节, 后面98个字节不用了, 就把它们free了.
你认为这样可以吗?

---

在mac中结果如下:

```
wo
a.out(26501,0x7fff780d2000) malloc: *** error for object 0x7fd201c032e2: pointer being freed was not allocated
```

为什么会说未分配呢?

其实, 问题与free申请好的内存的时候不需要指定释放多少size的内存有关.
因为在```malloc(100)```的时候, 不仅仅申请了100的内存, 还申请多了4字节或者8字节的内存, 用来存放
额外的数据来记录内存的大小.

free的时候, 就去读取这里面的信息, 得到100, 然后释放从参数指针所指的内存开始到100字节后结束.

假如, 我们free了c+2的地址, 那时候找到的长度信息就不是100而是其他了, 释放的内存说不定多于100, 于是mac下就给出如此的警告.
