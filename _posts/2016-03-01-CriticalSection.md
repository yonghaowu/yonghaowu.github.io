---
layout: post
title: CriticalSection的测试
description: 在Wine中对CriticalSection做测试
categories:
- 技术
tags:
- Wine


---

```
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#define NLOOP 5000
int counter; /* incremented by threads */ pthread_mutex_t counter_mutex = PTHREAD_MUTEX_INITIALIZER;
void *doit(void *);
int main(int argc, char **argv)
{
    pthread_t tidA, tidB;
    pthread_create(&tidA, NULL, doit, NULL); pthread_create(&tidB, NULL, doit, NULL);
    /* wait for both threads to terminate */
    pthread_join(tidA, NULL);
    pthread_join(tidB, NULL);
    return 0;
}

void *doit(void *vptr)
{
    int i, val;
    /*
     * Each thread fetches, prints, and increments the counter
     NLOOP times.
     * The value of the counter should increase monotonically. */
    for (i = 0; i < NLOOP; i++) {
        pthread_mutex_lock(&counter_mutex);
        val = counter;
        printf("%d\t", val +1);
        counter = val + 1;
        pthread_mutex_unlock(&counter_mutex);
    }
    printf("final counter is %d\n", counter);
}
```


  解释是: 两个线程一起运行后, 便分别对全局变量counter进行加一, 5000次循环.
而critical section就在加一赋值里起作用, 目的是为了防止在进行此操作时,刚好另外一个线程又有在操作, 导致结果错乱.

  第一个打印9997意味着第一个线程首先完成了5000次对counter+1的循环,此时counter的值为9997
而另外一个线程剩下3次循环, 最后运行完, 便是10000.
  可知, 如果critical section实现正确, 无论如何, 最终结果都为10000, 而其他两个线程的final counter则是未知, 因为你无法预知哪个线程运行的快 

  而在wine里make test的结果则是1 1 2 2 ....4999 4999 5000 5000	final counter is 5000
说明根本就没有锁到全局变量, 在counter还没有加一的时候线程已经读取全局变量了, 就出现这个结果.
所以实现不对
