---
layout: post
title: 如何在hexa skill里引用第三方库
description: 如何在golang程序里引用第三方库?
categories:
- 技术
tags:
- go
---

1. 自己用swig写项目的wrapper, 或者到网上找别人写好的wrapper, 如[go-opencv](https://github.com/lazywei/go-opencv), 本例将使用opencv做演示. 注意, 第三方库的wrapper要放在自己的项目中的vendor目录下.

2. 到机器人上, 把第三方库安装包都下载, 拷贝到自己的本地机器中

```
aptitude clean
aptitude --download-only install <your_package_here>
cp /var/cache/apt/archives/*.deb <your_directory_here>
```

3. 使用以下命令解压所有的包到你的文件夹

```
cd <your_directory_here>
mkdir files
IFS='
'
for debPackage in `ls`; do dpkg-deb -X $debPackage ./files; done
```

4. 拷贝出files/usr/里的include与lib文件夹到项目的assets文件夹里, 注意, 可能部分符号链接会失效, 到时将他们删除即可, 不影响效果. 参考: http://stackoverflow.com/questions/22097130/delete-all-broken-symbolic-links-with-a-line

5. 根据go-wrapper来修改pc文件或者环境变量. 如上述的go-opencv依赖lib/arm-linux-gnueabihf/pkgconfig里的pc文件, 则修改pc文件的文件依赖关系, 假设skillID为1c94030857350ece949698de0f00868e:

```
var='prefix=/var/local/mind/skills/1c94030857350ece949698de0f00868e/assets'
var2='exec_prefix=${prefix}'
var3='libdir=${prefix}/lib/arm-linux-gnueabihf'
IFS='
'
for pcfile in `ls`; do sed -ie "1 s#.*#${var}#" $pcfile && sed -ie "2 s#.*#${var2}#" $pcfile && sed -ie "3 s#.*#${var3}#" $pcfile; done
```

替换后, opencv的pc文件为:
```
prefix=/var/local/mind/skills/1c94030857350ece949698de0f00868e/assets
exec_prefix=${prefix}
libdir=${prefix}/lib/arm-linux-gnueabihf
includedir_old=${prefix}/include/opencv
includedir_new=${prefix}/include
```
