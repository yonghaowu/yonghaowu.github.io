---
layout: post
title: 汇编与C之间的关系
description: 研究函数的调用过程, %ebp, %esp分别的作用是什么.
categories:
- 技术
tags:
- C++
---

一个程序在运行过程中，函数调用时会向栈压入: 原来寄存器ebp的值, 参数, 以及调用函数的下一个指令地址
在调用一个函数时, 编译器就计算好函数需要的空间, 然后esp = ebp-需要的空间, 通过ebp+偏移量来访问. 在函数里调用另外一个函数时, 原来fun的ebp值压栈

```
#include <stdio.h>
int fun(int a, int b)
{
    int c = a+b;
    return c;
}
int main(void)
{
    fun(123, 456);
    int d = 98;
    printf("%d\n", d);
}

```

此程序的汇编是:

```
0000000100000f30 <_fun>:
   100000f30:	55                   	push   %rbp
   100000f31:	48 89 e5             	mov    %rsp,%rbp
   100000f34:	89 7d fc             	mov    %edi,-0x4(%rbp)
   100000f37:	89 75 f8             	mov    %esi,-0x8(%rbp)
   100000f3a:	8b 75 fc             	mov    -0x4(%rbp),%esi
   100000f3d:	03 75 f8             	add    -0x8(%rbp),%esi
   100000f40:	89 75 f4             	mov    %esi,-0xc(%rbp)
   100000f43:	8b 45 f4             	mov    -0xc(%rbp),%eax
   100000f46:	5d                   	pop    %rbp
   100000f47:	c3                   	retq
   100000f48:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
   100000f4f:	00

0000000100000f50 <_main>:
   100000f50:	55                   	push   %rbp
   100000f51:	48 89 e5             	mov    %rsp,%rbp


   100000f54:	48 83 ec 10          	sub    $0x10,%rsp
   100000f58:	bf 7b 00 00 00       	mov    $0x7b,%edi
   100000f5d:	be c8 01 00 00       	mov    $0x1c8,%esi
   100000f62:	e8 c9 ff ff ff       	callq  100000f30 <_fun>
   100000f67:	48 8d 3d 44 00 00 00 	lea    0x44(%rip),%rdi        # 100000fb2 <_main+0x62>
   100000f6e:	c7 45 fc 62 00 00 00 	movl   $0x62,-0x4(%rbp)


   100000f75:	8b 75 fc             	mov    -0x4(%rbp),%esi
   100000f78:	89 45 f8             	mov    %eax,-0x8(%rbp)
   100000f7b:	b0 00                	mov    $0x0,%al
   100000f7d:	e8 0e 00 00 00       	callq  100000f90 <_main+0x40>
   100000f82:	31 f6                	xor    %esi,%esi
   100000f84:	89 45 f4             	mov    %eax,-0xc(%rbp)
   100000f87:	89 f0                	mov    %esi,%eax
   100000f89:	48 83 c4 10          	add    $0x10,%rsp
   100000f8d:	5d                   	pop    %rbp
   100000f8e:	c3                   	retq
```

对于以上的程序, 栈的布局是这样的:

```
0x123 rbp(main)
0x11f c
0x11b b
0x117 a
0x113 rbp(foo) rsp(main,foo)
100000f30 <调用fun下一个指令地址>
```

粗略来说, 就是ebp指向栈底, esp指向栈顶第一个参数的地址, 在本例中就是&a

在调用一个函数时, 编译器就计算好函数需要的空间, 然后esp = ebp-需要的空间, 通过ebp+偏移量来访问
在函数里调用另外一个函数时, 原来fun的ebp值压栈, 

```
ebp = esp
esp = ebp-需要的空间
借此调用另外的函数
```

退出时会做函数调用时的逆操作, 看伪代码:

```
pop ebp
esp = ebp
esp = ebp+需要的空间
```

内层函数是通过之前已经压栈了的调用函数时的下一条指令来得知返回地址的.
