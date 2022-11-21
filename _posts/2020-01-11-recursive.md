---
layout: post
title: 递归的实现
description:
categories:
- 技术
tags:
- go
---

## 递归的实现——循环，汇编，CPS与 y 组合子

![公众号](https://img-blog.csdnimg.cn/20210211125314723.jpg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hpb2hpb2h1,size_16,color_FFFFFF,t_70#pic_center)

##### 递归和循环是等价的

如果定义一个概念需要用到这个概念本身，我们称它的定义是递归的（Recursive）。例如：

- beautiful

  an adjective used to describe something that is beautiful.

*递归和循环是等价的* ，用循环能做的事用递归都能做，反之亦然。

举例子：

```
int loop(int n) {
    int sum = 0;
    for(int i=0; i<n; i++) {
          sum += i;
    }
    return sum;
}
```

逻辑等价于：

```
void loop(int i, int n) {
     if(i < n) {
         return i + loop(i+1, n);
     } else {
         return 0;
     }
}
loop(0, 10);
```



事实上有的编程语言（比如某些 LISP 实现）只有递归而没有循环。计算机指令能做的所有事情就是数据存取、运算、测试和分支、循环（或递归），在计算机上运行高级语言写的程序最终也要翻译成指令，指令做不到的事情高级语言写的程序肯定也做不到，虽然高级语言有丰富的语法特性，但也只是比指令写起来更方便而已，能做的事情是一样多的。



####调用函数与递归的汇编实现

#####调用函数的汇编实现

在执行程序时，操作系统为进程分配一块栈空间来保存函数栈帧，每次调用一个函数都要分配一个栈帧来保存参数和局部变量。

```
#include <stdio.h>
int fun(int a, int b)
{
    int c = a+b;
    return c;
}
int main(void)
{
    int d= fun(123, 456);
    return d;
}
```

执行：

```
gcc main.c -g  #在编译时加上 -g 选项，用 objdump 反汇编时可以把 C 代码和汇编代码穿插起来显示
objdump -dS a.out
```

反汇编的结果很长，以下只列出我们关心的部分：

```
00000000004004d6 <fun>:
#include <stdio.h>
int fun(int a, int b)
{
  4004d6:	55                   	push   %rbp
  4004d7:	48 89 e5             	mov    %rsp,%rbp
  4004da:	89 7d ec             	mov    %edi,-0x14(%rbp)
  4004dd:	89 75 e8             	mov    %esi,-0x18(%rbp)
    int c = a+b;
  4004e0:	8b 55 ec             	mov    -0x14(%rbp),%edx
  4004e3:	8b 45 e8             	mov    -0x18(%rbp),%eax
  4004e6:	01 d0                	add    %edx,%eax
  4004e8:	89 45 fc             	mov    %eax,-0x4(%rbp)
    return c;
  4004eb:	8b 45 fc             	mov    -0x4(%rbp),%eax
}
  4004ee:	5d                   	pop    %rbp
  4004ef:	c3                   	retq
  
00000000004004f0 <main>:
int main(void)
{
  4004f0:	55                   	push   %rbp
  4004f1:	48 89 e5             	mov    %rsp,%rbp
  4004f4:	48 83 ec 10          	sub    $0x10,%rsp
    int d= fun(123, 456);
  4004f8:	be c8 01 00 00       	mov    $0x1c8,%esi
  4004fd:	bf 7b 00 00 00       	mov    $0x7b,%edi
  400502:	e8 cf ff ff ff       	callq  4004d6 <fun>
  400507:	89 45 fc             	mov    %eax,-0x4(%rbp)
    return d;
  40050a:	8b 45 fc             	mov    -0x4(%rbp),%eax
}
```



`main` 函数太特殊了，我们先把`fun`函本身数的过程的汇编代码过一遍。

必须要知道的前置知识是： 在 x86 平台上这个栈是从高地址向低地址增长的，`esp` 寄存器总是指向栈顶，`ebp` 总是指向当前栈帧的栈底。32位开头的x86汇编，是e 开头，如 esp，ebp；64位是r 开头，如 rsp，rbp。

由于给出的例子都在我本机（64位）进行测试，命名都用 r 开头。



```
int fun(int a, int b)
{
  4004d6:	55                   	push   %rbp
  4004d7:	48 89 e5             	mov    %rsp,%rbp
```



`push %rbp` 指令等价于下面两条指令：

> subq $8, %rsp （用伪语言介绍就是：%rsp = %rsp - 8，因为`rsp` 寄存器总是指向栈顶，所以 esp栈指针-8，指向下面8字节后的地方，压了数据进栈后，指针要变嘛。）
>
> movq %rbp, (%rsp)  （ 也就是： rsp的值 = rbp 的值，将 rbp 的数据放进栈顶指针 rsp 指向的地方）



注意的是，main 函数是最先调用的，所以这里的 rbp 值是 main 函数的栈底指针。

这里为什么要把main函数中的 rbp 的值压栈呢？

要注意`rbp` 总是指向当前栈帧的栈底，所以是不会有任何变动的，会利用 `rbp + 偏移值`来访问栈里的变量。

但是呢，全局只有一个 rbp 寄存器， main 函数原来的 rbp 值（也就是栈底）假设是0x1234，在 fun 函数时，rbp 值就要改变成 fun 函数的栈底指针了。



`  4004d7:	48 89 e5             	mov    %rsp,%rbp`

这里，为什么又把main 函数 rsp （栈顶）的值赋值给 foo 函数的 rbp（栈底）呢？因为一个线程（thread）只有一个栈，函数都是公用一个栈的。所以，main 函数的栈与 foo 函数的栈是连在一起的——也就是说，main 的栈顶就是 foo 函数的栈底。



栈的布局是这样的:

```
0x123 rbp(main栈底)[实际并不存在，是以前的值，便于理解]
0x11f c
0x11b b
0x117 a
0x113 rbp(foo栈底) rsp(main栈顶,foo栈顶)
0x109 rsp(foo 栈顶)-4 ， foo有多少参数，就这样往下跑。
```





接下来就是真正执行 foo 函数内的过程了：

```
  4004da:	89 7d ec             	mov    %edi,-0x14(%rbp)
  4004dd:	89 75 e8             	mov    %esi,-0x18(%rbp)
    int c = a+b;
  4004e0:	8b 55 ec             	mov    -0x14(%rbp),%edx
  4004e3:	8b 45 e8             	mov    -0x18(%rbp),%eax
  4004e6:	01 d0                	add    %edx,%eax
```

`esi`与`edi`通常代表不变的值，用来放函数的参数。

注意`%edi` 与 `%esi`已经在 main 函数体里，在调用 foo 之前赋值了：

```
  4004f8:	be c8 01 00 00       	mov    $0x1c8,%esi
  4004fd:	bf 7b 00 00 00       	mov    $0x7b,%edi
  400502:	e8 cf ff ff ff       	callq  4004d6 <fun>
```

所以现在的内存布局是这样的：

```
0x123 rbp(main栈底)[实际并不存在，是以前的值，便于理解]
0x11f c
0x11b b
0x117 a
0x113 rbp(foo栈底) rsp(main栈顶)[实际并不存在，是以前的值，便于理解]
0x099 123
0x095 456 rsp(foo栈顶)
```



foo 函数的汇编就是把`$0x7b（10进制是123）`与`$0x1c8（10进制是456）`分别存在 edx 与 eax，然后做加运算，结果在`eax`上（返回值通过 `eax` 寄存器传递）

最后:

```
  4004e8:	89 45 fc             	mov    %eax,-0x4(%rbp)
    return c;
  4004eb:	8b 45 fc             	mov    -0x4(%rbp),%eax
}
  4004ee:	5d                   	pop    %rbp
  4004ef:	c3                   	retq
```

把`123 + 456`得出的在 eax 的值，赋值给 rbp（栈底）-4的地方，弹出 rbp （栈顶）原来的值（main 的栈顶），调用 retq 指令（retq 是 call 的逆指令），返回到原来 call 的地址后运行。



##### 递归的汇编实现

递归无非就是嵌套的函数调用，a 函数调用回 a 函数，不停的调用 call 指令，rbp（栈顶）不停往下跑，如：

```
0x123 rbp(main栈底)[实际并不存在，是以前的值，便于理解]
0x11f c
0x11b b
0x117 a
0x113 rbp(foo栈底) rsp(main栈顶)[实际并不存在，是以前的值，便于理解]
0x099 123
0x095 456 rsp(foo栈顶) 
假设 foo 是递归函数：
0x113 rbp(新foo栈底) rsp(旧的foo栈顶)[实际并不存在，是以前的值，便于理解]
0x099 123
0x095 456 rsp(新foo栈顶) 
。。。

```

最终，如果没有终止条件，自然栈的容量超过操作系统允许的一个进程的最大值，stackoverflow（栈溢出）



#####尾调用 (tail call) 和尾递归 (tail recursion)

* 非尾递归算法，需要 O (n) 的调用栈空间

* 尾递归是尾调用的特殊情形，尾调用并不要求 callee 和 caller 是同一个函数。

* 尾递归太特殊了，太容易优化了，所以在源码层面就能做递归到迭代的变换。

而一般的尾调用，callee 可能和 caller 没有任何联系，优化就只能寄期望于编译器或虚拟机了。





说到递归，不得不说递归的一种特殊形式：**尾调用 (tail call)**，指一个函数里的最后一个动作是返回一个函数的调用结果的情形。

而**尾递归 (tail recursion)**是为调用的的特殊情形，callee 和 caller 是同一个函数，而尾调用并不要求 。因此尾递归可以很简单的就可以做优化。

而一般的尾调用，callee 可能和 caller 没有任何联系，优化就只能寄期望于编译器或虚拟机了。



```
void foo(int a, b){
    bar(a+12, b*99+a)
}
```

就是尾调用。



而

```
void foo(int a, b){
    foo(a+12, b*99+a)
}
```

就是尾递归。

但是

```
void foo(int a, b){
    12 + foo(a, b)
}
```

就啥都不是，只是递归。



尾递归的优化从函数调用的汇编实现很容易理解，只要不涉及多余的参数（也就是不用额外的栈容量存，栈顶不用往下扩展再调用回函数），直接就可以改变 `%edi`, `%esi`的值，重新调用函数，也就是说不用任何额外的栈变量。



我想举一个尾递归以及非尾递归的例子的汇编代码在此，结果发现，gcc 除了对尾递归优化，已经用了黑科技优化递归- = - （clang 没有）。

```
   int sum (int n) {
     if (n > 0)
       return n + sum (n - 1);
     else
       return 0;
   }
```

会优化成：

```
   int sum (int n) {
     int acc = 0;
     while (n > 0) {
       acc += n;
       n -= 1;         
     }
     return acc;
   }
```



只查到 gcc 的源码实现， 根据注释，优化的规律是这样的：

设两个变量a_acc = 0 , m_acc = 1

对于`a + m* f(...)` 的递归形式，都拓展成`a_acc + (a + m * f(...)) * m_acc`，

`a_acc + (a + m * f(...)) * m_acc = (a_acc + a * m_acc) + (m * m_acc) * f(…)`

可以参考 gcc 的源码https://github.com/gcc-mirror/gcc/blob/master/gcc/tree-tailcall.c， 我暂时还没有搞懂这个优化是怎么做的。



##### 任何的递归，都可以转换成尾调用，然后优化。

* 如果算法本身就是尾递归的，那么，可以直接改写成迭代，这是尾调用优化的一种特例。

* 如果算法本身是非尾递归的，那么，CPS 变换可以将算法改写成尾调用形式，从而可以进行尾调用优化。

  改写过后的空间复杂度仍然是 O (n)，只不过是从 O (n) 的栈变成了 O (n) 的 continuation chain，这个改变对支持尾调用优化的简单解释器是有意义的。



此节的知识皆来自于此答案，在下只是做了推演：

https://www.zhihu.com/question/28458981/answer/40941851

 我抄袭一下答案来讲解一下里面的`Lua`代码：

```
-- 递归版本
function sum(n)
    if n == 0 then
        return n
    else
        return n + sum(n - 1)
    end
end

-- 对于sum，很容易找到尾递归版本
function sum_tail(n, result)
    if n == 0 then
        return result
    else
        return sum_tail(n - 1, result + n)
    end
end

-- 尾递归版本可以直接翻译成迭代: 外层增加while true，将每个递归调用改成修改形参再continue
function sum_iter(n, result)
    while true do
        if n == 0 then
            return result
        else
            n, result = n - 1, result + n
        end
    end
end

-- 对非尾递归算法(sum)进行CPS变换，使得所有调用都变成尾调用，从而允许解释器做尾调用优化
function sum_cps(n, k)
    if n == 0 then
        return k(n)
    else
        return sum_cps(n - 1, function(result)
            return k(result + n)
        end)
    end
end

-- CPS + trampoline，不再依赖解释器的尾调用优化
function trampoline_driver(v, k)
    while k do
        v, k = k(v)
    end
    return v
end
function sum_trampoline(n, k)
    if n == 0 then
        return n, k
    else
        return nil, function()
            return sum_trampoline(n - 1, function(result)
                return result + n, k
            end)
        end
    end
end

-- 递归深度为N
local N = 100000
print(sum(N)) -- 溢出
print(sum_tail(N, 0)) -- 利用解释器的尾调用优化，不溢出
print(sum_iter(N, 0)) -- 直接改写成迭代，当然不溢出
print(sum_cps(N, identity)) -- 从非尾递归版本sum改写来的，依赖解释器的尾调用优化，不溢出
print(trampoline_driver(sum_trampoline(N, identity))) -- 既不依赖解释器的尾调用优化，也不溢出
```



递归，尾递归以及迭代的版本很容易看懂就不讲了，主要讲讲递归的 CPS变换以及CPS + trampoline（蹦床），即是怎么把递归转成普通的函数链调用。

```
print(sum_cps(N, identity)) -- 从非尾递归版本sum改写来的，依赖解释器的尾调用优化，不溢出
print(trampoline_driver(sum_trampoline(N, identity))) -- 既不依赖解释器的尾调用优化，也不溢出
```



### 递归的 CPS变换

```lua
N = 10000
id = λ x:x
sum_cps(N, identity)
-- 对非尾递归算法(sum)进行CPS变换，使得所有调用都变成尾调用，从而允许解释器做尾调用优化
function sum_cps(n, k)
    if n == 0 then
        return k(n)
    else
        return sum_cps(n - 1, function(result)
            return k(result + n)
        end)
    end
end
```

以 `sum_cps(2, λ x:x)` 为例子，其中设`函数id`为 `λ x : x`

调用展开如下：

* `sum_cps(2, identity)` 
* `return sum_cps(1, λ result : id(result + 2)  end)`
* `return sum_cps(0, λ result : (λ result : id(result + 2)) (result+1)  )`
* `return （λ result : (λ result : id(result + 2)) (result+1)）(0)` 最后调用0

把0代入进去，计算最后的结果即可，也就是：

* ` (λ result : id(result + 2)) (0+1)`
* `id(0+1  +2)`
* `id(3)`

也就是3，其实` CPS 转换`就是，原来递归版本` On` 的栈的函数参数，转换成一个个尾调用函数的调用链。

这样子支持尾调用的编译器（解释器）就能够对此进行优化，



####  CPS + trampoline（蹦床）

```lua
identity = λ x: x, nil
trampoline_driver(sum_trampoline(N, identity))

-- CPS + trampoline，不再依赖解释器的尾调用优化
function trampoline_driver(v, k)
    while k do
        v, k = k(v)
    end
    return v
end
function sum_trampoline(n, k)
    if n == 0 then
        return n, k
    else
        return nil, function()
            return sum_trampoline(n - 1, function(result)
                return result + n, k
            end)
        end
    end
end
```

同样，我们展开看看：

* `trampoline_driver( sum_trampoline(3, identity) )`
* `trampoline_driver( nil,  λ: sum_trampoline(2, λ result: result + 3, identity) )`
* `v, k = λ: sum_trampoline(2, (λ result: result + 3, identity) ) (nil) `
* `v, k = nil, (λ: sum_trampoline(1, λ result: result + 2, (λ result: result + 3, identity) )  )(nil)`
* `v, k = nil,  λ: sum_trampoline(0, (λ result: result + 1,  λ result: result + 2, (λ result: result + 3, identity)) ) （nil）`
* `v, k = 0, (λ result: result + 1,  λ result: result + 2, (λ result: result + 3, identity))(0) `
* `v, k = (λ result: result + 1,  λ result: result + 2, (λ result: result + 3, identity)) (0)`
* `v, k = (0 + 1,  λ result: result + 2, (λ result: result + 3, identity)) `
* `v, k =  λ result: result + 2, (λ result: result + 3, identity)) (1)`、
* `v, k = 0 + 1 + 2, (λ result: result + 3, identity)) `
* `v, k = (λ result: result + 3, identity)(3)`
* `v, k =  0 + 1 + 2 + 3,  identity `
* `v, k = identity( 0 + 1 + 2 + 3)`
* `v, k = 6, nil`
* `return v`

就是这样，不停的循环将得到的未执行的函数(A thunk, in programming language jargon, is simply some expression wrapped in an argument-less function.)传递给 k，最后反过来调用 - = -

那为什么叫trampoline（蹦床）呢？

看它最后在在求值时，也即是：

```
- v, k = 0, (λ result: result + 1,  λ result: result + 2, (λ result: result + 3, identity))(0)
- v, k = (λ result: result + 1,  λ result: result + 2, (λ result: result + 3, identity)) (0)
- v, k = (0 + 1,  λ result: result + 2, (λ result: result + 3, identity))
- v, k =  λ result: result + 2, (λ result: result + 3, identity)) (1)、
- v, k = 0 + 1 + 2, (λ result: result + 3, identity))
- v, k = (λ result: result + 3, identity)(3)
- v, k =  0 + 1 + 2 + 3,  identity
```

是不是相当于弹起来一个 v，再回到去原来的蹦床（在这里是 k），重新求值把 v 弹出来。







### 组合子

递归是靠有名字的函数来实现的。

```
let fun = λ x: fun(x)
fun(x) # 这样子是递归函数
```



如果在没有实现变量绑定的解释器里（例如自己写的简陋的解释器），怎么样实现递归呢？

`λ x: ???(x)` 里， `???` 该填上什么呢？



**在 lambda 演算里确实没有 let**， 对此前人已经找出了解决方法，要讲清楚 Y 的来龙去脉，可是非常难。事实上，连发现它的哈斯卡大神也感慨不已，觉得自己捡了个大便宜，还因此将 Y 纹在了自己的胳膊上。我现在就只讲 Y 的用处了。

 `Y` 大概是，先制造一个不断的返回自身的整个函数体，最后到了返回 `自身的函数体=真正的自身`【也就是数学上的不动点，将函数应用于自身得到自身， x = f(x) 】时，就实现了递归了 - = -，有兴趣可以查查。--
