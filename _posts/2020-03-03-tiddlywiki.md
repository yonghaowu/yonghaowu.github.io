---
layout: post
title: Notion?Roam?OneNote?做笔记我用Tiddlywiki
description: 
categories:
- 技术
tags:
- go
---

![公众号](https://img-blog.csdnimg.cn/20210211125314723.jpg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hpb2hpb2h1,size_16,color_FFFFFF,t_70#pic_center)

## 双向链接

最近因为Roam Research，双向链接在笔记圈子里火了起来，Notion也在准备做了，那么双向链接是什么呢？



我用我的我关于管道的一则笔记给大家讲明白：

管道的实现

Linux里，管道实现的原理是：Shell进程先调用`pipe`创建一对管道描述符，然后`fork`出两个子进程，一个子进程关闭读端，调用`dup2`把写端赋给标准输出，另一个子进程关闭写端，调用`dup2`把读端赋给标准输入，两个子进程分别调用`exec`执行程序，而Shell`进程`把管道的两端都关闭，调用`wait`等待两个`子进程`终止。



如上，管道的实现就是我可以从其他地方点击看这个笔记内容的单向链接，只能从名字过来。

但对于我上面笔记里标红的关键词，笔记系统会提炼出关键词，并且给这些关键词自动生成/引用到有这个名字的笔记里。

那么，我以后想看`dup2`这个函数的详情，就可以看到关于`dup2`的解释，以及有什么笔记用过它。



词不达意，稍后再截图说清楚。



## 选择什么好呢？

我比较喜欢稳定的折腾，不太喜欢breaking change，所以我一般选择依赖很重的工具时，会尽量选择breaking change不多的——比如vim，稳定+自定义强+简单，在不是必须IDE时我开发都用`Vim+tmux+bash+git`，选笔记时，我认为这会是长年使用的工具，所以我会偏向使用这种。

下面列列：

* Notion：太重了，我入门感觉就是啥模板都有，而且比较强调协作，面向大众，没发现有双向链接（后来得知在实现中）
* Roam Research：带火双向链接的创始者，收费贵，创始人言论有问题，言下之意是，收费贵就是筛选掉你们这些不愿意付钱没信仰的人
* Obisdian：想跟Roam Research抢市场的后来者，不完善，界面不好看，没给我想要的感觉

以上都没给我印象强烈的点。



直到我继续看`Roam Research`的替代品，在一大堆替代品中，看到了熟悉的名字：`TiddlyWiki`。



## 再遇TiddlyWiki

我是Erlang作者Joe Armstrong的粉丝，三言两语讲不清楚（讲清楚就得下篇了），所以我很早就知道了`TiddlyWikil`了，因为他后来就用了这个当博客用（点击原文可查看他的博客）。

他用`TiddlyWikil`是因为对Jelly、Hugo这些博客使用markdown时，因为格式不统一上传时才有问题，不太满意；另外是他希望他写的东西，之后不会因为markdown格式问题（100年后没有markdown解释器了）而不可读：

* The blog is a program.
* You can interact with the blog.
* The blog contains most of the articles I've written in the last few years.
* The blog is made from a single HTML file which should run off-line in any browser.
* The blog contains a complete IDE powerful enough to recreate itself.
* The blog is a Quine.
* I hope the blog will be readable in 100+ years time.

当时对我来说，这些点有点意思，但对我完全不重要。。

而且说实话，`TiddlyWiki`其实对不了解的人来说挺反直觉的——毕竟是笔记系统，大多数人会认为别扭，包括我。

## 真香

这次，我看到了这个笔记系统的闪光点了，玩弄了一番后，觉得大有可为，于是便去了解一番。

接着就是用了很久了，分享一下截图：



那么，`TiddlyWiki`优缺点有哪些呢？

### 优点

* 自定义强，插件也丰富，官方也有维护官方插件库（就像IDE的插件一样）；
* 纯静态HTML，我的地盘我做主，同步到GitHub page也方便；
* 免费开源

### 缺点

* 非常小众，国内用的人屈指可数——我以后能像Python之父廖雪峰那样，混个TiddlyWiki + Elixir之父山尽吗？？滑稽
* 入门门槛高一些，geek一点的人才能比较好的运用它；
* 后端同学可能不太会前端——幸亏对我来说不是问题；
* 没有像RoamSearch那么成熟的 tag 关联（就是关键词关系图），不过我认为对于程序员来说，目录还是很重要的。

我都写了，证明我的推荐度是100分的。





欢迎大家使用，Make Tiddlywiki Greater Again
