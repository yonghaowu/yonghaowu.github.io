---
layout: post
title: golang作用域
description: golang的:=操作符虽然方便,但在作用域上也带来了潜在的疑惑和危险.
categories:
- 技术
tags:
- go
---

大家看看这段代码能否准确的说出输出语句是什么?

```
package main

import "fmt"

var a int

func funca() {
	a, b := 12, 3
	fmt.Println("a is ", a, " b is ", b)
}
func funcb() {
	fmt.Println("a is ", a)
}
func main() {
	funca()
	funcb()

	c := 8
	fmt.Println("c is ", c)
	c, d := 9, 10
	fmt.Println("c is ", c, " d is ", d)
}
```

是的,输出的是

```
a is  12  b is  3
a is  0
c is  8
c is  9  d is  10
```

已经定义好的变量在同一作用域里, 在多赋值(:=)时, :=的作用只是赋值, 就像main函数里对C的作用一样.

但是在该作用域里并没有定义时, := 会是创建新变量. 如funca就会创建局部变量a,覆盖掉全局的a变量.
