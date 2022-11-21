---
layout: post
title: C/C++编译链接与装载深入浅出
description: 系列第一篇, 本文尝试从汇编开始, 由浅入深的讲解编译与链接, 以及介绍ELF标准格式以及目标文件.
categories:
- 技术
tags:
- C++
---

## 编译的详细过程
以hello.c的源文件为例, C/C++编译, 链接与装载的流程是

1. ```gcc -E``` 将hello.c预处理, 把所有的宏展开, 解析#ifndef, 删除注释等, 得到translation unit(编译单元) hello.i文件.
2. ```gcc -S``` 将hello.i编译成汇编文件hello.s
3. ```gcc -c``` 汇编器as将hello.s编译成成目标文件hello.o
4. ```gcc   ``` 链接器ld将hello.o链接成可执行文件a.out

## 最简单的汇编程序

```
.section .data

.section .text
.globl _start
_start:
    movl $1, %eax
    movl $77, %ebx
    int $0x80
```

将这个文本保存成hello.s, 再用汇编器(Assembler)把汇编程序中的助记符翻译成机器指令, 生成目标文件hello.o

```
$ as hello.s -o hello.o
``` 

然后用链接器(Linker, 或Link Editor)ld把目标文件hello.o链接成可执行文件hello:

```
$ ld hello.o -o hello 
```

这个程序只是做了一件事: 退出.

退出状态(Exit Status)为77, 在Shell中可以用特殊变量$?得到上一条命令的退出状态

```
$ ./hello
$ echo $?
77
```

## .section到ELF文件

### .section会成为目标文件的Section
简单起见, 以上汇编程序只是想告诉大家, 注意以上的.section后的.data与.text

汇编程序中以.开头的名称不会被翻译成机器指令, 而是给汇编器一些特殊的指示, 称为汇编指示(Assembler Directive)或伪操作(Pseudo-operation), 由于它不是真正的指令所以加个“伪”字.

.section指示把代码划分成若干个段(Section), 程序被操作系统加载执行时, 每个段被加载到不同的地址, 具有不同的读、写、执行权限。
.data段保存程序的数据, 是可读可写的, C程序的全局变量也属于.data段. 本程序中没有定义数据, 所以.data段是空的

所以, 我们的hello.c源代码经过```gcc -S``` 翻译后, 就得到伪操作以及一些运算指令(hello.s).
接着, 使用```as hello.s```根据段信息等得到目标文件hello.o, 目标文件由若干个Section组成, 我们在汇编文件中声明的.section会成为目标文件的Section, 此外汇编器会自动添加一些Section(比如符号表).

C程序编译后的执行语句都翻译成机器指令放在.text段, 已初始化的全局变量和局部静态变量放在.data段, 未初始化或者默认初始化(即是0)的全局变量和局部静态变量放在.bss的段里, 有.bss段的目的是为了节省内存空间, 因为都为0, 只需要为它们预留位置即可.

### 为什么不把指令跟数据全部放在一个section呢?

1. 各个Section可以划分权限, 如.data为可读可写, .rodata与.text只可读.
2. 指令跟数据划分得更细, 可以让缓存的命中率提高.
3. 共享资源. 当多个相同的进程同时运行时, 可以共享.text, .rodata等. 当进程里有很大图片, 文本等资源时就可以节省大量空间.

### 目标文件是ELF文件
ELF(Executable and Linking Format)是一个开放标准, 各种UNIX系统的可执行文件都采用ELF格式, 它有四种不同的类型:

* 可重定位的目标文件(Relocatable, 或者Object File), Linux的.o, Windows的.obj
* 可执行文件(Executable), Linux的.out, Windows的.exe
* 共享库(Shared Object, 或者Shared Library), Linux的.so, Windows的.DLL
* 核心转储文件(Core Dump File)a, Linux下的core dump

大家想想, 当我们编译多个文件时, 就会有多个目标文件. 
当A文件使用B文件的函数时, A文件是如何得知B文件函数的地址是什么呢?
这个过程, 就叫做重定位.

下一篇我们讲解, 重定位, 重定位表, 符号等.


## 参考资料
本文几乎可以算是对"Linux C一站式学习", "程序员的自我修养-链接装载与库"的归纳整理.
