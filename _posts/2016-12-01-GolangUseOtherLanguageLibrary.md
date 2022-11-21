---
layout: post
title: Golang调用第三方库
description: 
categories:
- 技术
tags:
- go
---

##C++##

1. 使用[The Simplified Wrapper and Interface Generator (SWIG)](http://swig.org/)

需要编写swig文件, 如果C++项目里只有原生类型的话,只需要写

```
%module simplelib  //name of the resulting GO package

%include "simpleclass.h"

然后用
swig -go -cgo -c++ -intgosize 64 example.swig
生成可调用文件即可
```

如果是有vector,string等用了模板的类的话, 可就麻烦多了.

2. 使用extern C来wrap C++的代码, 然后用Cgo来编译. 为什么需要用extern "C"来当做C语言处理呢? C++兼容C, 直接用应该也没有问题吧?

原因就是上述的符号改编(NAME Mangling), 试想一下使用C中string.h里而不是C++中string的memset的时候, 如果不限定extern "C"的时候, 就会进行符号改编从而使用了C++里string的memset, 使用extern "C"就不会进行符号改编从而链接到正确的C函数. 

##C语言##
纯C语言的库， 可以使用Cgo，只需要用gcc编译成.o文件并压缩成.a 文件， 在使用C语言的go代码里添加上一些调用C语言的头文件与选项就好了。
