---
layout: post
title: golang生成binary package
description: 虽然go1.5支持共享库，但是由于golang并不能像C语言一样通过export，头文件与C文件分离，所以并不能实现与C语言一样，只提供头文件与共享库而不提供实现的方法。 go1.7引入了binary-package, 实现了以上C语言的功能，提供二进制包。
categories:
- 技术
tags:
- go
---

虽然go1.5支持共享库，但是由于golang并不能像C语言一样通过export，头文件与.C文件分离，所以并不能实现与C语言一样，只提供头文件与共享库而不提供实现的方法。

go1.7引入了[binary-package](https://tip.golang.org/pkg/go/build/#hdr-Binary_Only_Packages), 实现了以上C语言的功能，提供二进制包。

---

生成的步骤比较复杂, 因此我制作了一个可以生成二进制包以及fake.go(相当于C语言的头文件)的[golang-binary-package-generator工具](https://github.com/YongHaoWu/golang-binary-package-generator#golang-binary-package-generator)


### How to use it

1. Specify generatedDirs and projectName(which should be the deploy.sh 's parent directory name) in deploy.sh.
2. Execute ```$  ./deploy.sh```
3. Delete your framework implementation and move fakeGoPackagesPath 's fake go files to implementation's position.
4. Pack the .a files for your clients, which should be in $GOPATH/pkg/YourProjectName.

---
实质上程序完成了以下功能:

1. 使用```go build -i```编译需要提供二进制包的库, 生成的.a文件会自动放在```$GOPATH/pkg/darwin_amd64(linux有相对应文件夹)```里面, 推荐在使用前先清空该目录, 生成后打包即可. 或者通过-o指定位置, 到时候放在用户对应的上述文件夹里.

2. $GOPATH/src相应目录放入对应库目录的Go源文件，里面加入以下注释：

```
//go:binary-only-package
```

保留包的声明语句 package mypkg ， 保留包的文档信息时还可以用go doc查阅包文档。

---

这样，developer就可以只通过以上src里的空源文件与pkg的.a文件来使用库的API.

---

# Reference
* https://tip.golang.org/pkg/go/build/#hdr-Binary_Only_Packages
* https://github.com/tcnksm/go-binary-only-package
* http://ju.outofmemory.cn/entry/256338
