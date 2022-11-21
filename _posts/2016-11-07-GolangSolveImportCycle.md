---
layout: post
title: golang解决依赖循环问题(import cycle)
description: 网上一直没有靠谱的方法.
categories:
- 技术
tags:
- go
---

网上传的最多的方法就是[使用接口interface解决](http://mantish.com/post/dealing-with-import-cycle-go/)
这个文章,实际上, 我认为这个方法并不可行.
到作者的github项目上看, 他给出的例子并没有解决此问题(醉

不行的原因是: 假设原来B引用A, A引用B, 后来做出一个C的interface, 由A去实现, B依赖C, 看似很好, 实际上,
这种情况还是需要A的实例.

也就是说, B尽管用了接口, 还是会依赖A这个对象实例. 

从A把实例作为参数传给B才是解决方法.

---

**方法二:**

把A引用B的方法, 当做函数参数来传递. A用到B哪些函数, 就把哪些函数作为参数传递过去.

---

**方法三:**

最好的办法就是, 考虑整个项目的架构. 往往出现依赖问题, 是包的从属问题分析的不好.
