---
layout: post
title: How does apt-get work exactly?
description: apt-get install 的原理是什么?我们知道自己编译安装一个包的过程是./configure, make, make install. 但是, apt-get install 做了什么呢?
categories:
- 技术
tags:
- go
---

apt-get install 的原理是什么?我们知道自己编译安装一个包的过程是./configure, make, make install. 但是, apt-get install 做了什么呢?

1. 分析依赖并且下载相应的包, 以下命令会把相应的包都下载到本地.

```
aptitude clean
aptitude --download-only install <your_package_here>
cp /var/cache/apt/archives/*.deb <your_directory_here>
```

使用以下命令解压所有的包到你的文件夹

```
cd <your_directory_here>
mkdir files
IFS='
'
for debPackage in `ls`; do dpkg-deb -X $debPackage ./files; done
```

2. 把包里的include(项目提供的头文件), lib(项目的动态以及静态链接库), bin(二进制程序)拷贝到/usr/里的对应位置.

在此不得不说pkg-config的pc文件, 它会组织好编译程序时如何找对应的include以及lib目录, 以及指定编译选项. 如opencv的pc文件为:
```
prefix=/usr
exec_prefix=${prefix}
libdir=${prefix}/lib/arm-linux-gnueabihf
includedir_old=${prefix}/include/opencv
includedir_new=${prefix}/include
```
