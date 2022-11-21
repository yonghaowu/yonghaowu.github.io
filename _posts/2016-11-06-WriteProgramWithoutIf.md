---
layout: post
title: 不用if结构,如何写程序?
description: 不用if,else,三目运算符, switch, 如何写程序好?
categories:
- 技术
tags:
- go
---

例子:

```
int a = 12;
if(a > 10)
    cout<<"a is greater than 10"<<endl;
```

一个思考题, 不用if,else,三目运算符?: , switch, 如何写程序好?

---
1. do break

```
int a = 12;
for(; a>10; ;) {
    cout<<"a is greater than 10"<<endl;
    break;
}
```

2. && 

```
int a = 12;
a>10 && cout<<"a is greater than 10"<<endl;
```
