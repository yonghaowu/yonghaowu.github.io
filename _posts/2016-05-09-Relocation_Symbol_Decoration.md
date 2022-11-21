---
layout: post
title: C/C++编译链接与装载深入浅出其二
description: 系列第二篇, 
categories:
- 技术
tags:
- C++
---

当我们编译多个文件时, 就会有多个目标文件.
这些模块最后如何形成一个单一的程序呢?

## 模块间通信 
### 链接器的由来
C/C++模块之间通信的方式有两种, 一种是模块间函数调用, 另一种是模块之间的变量访问.
在编译成目标文件的时候, 由于没有办法得知所引用的外部函数或者外部变量的地址, 所以会先置0.
所以问题本质上就是, 如何得知目标函数或者目标变量的地址呢?

手动查找修改自然不是我们的方法, 这就是链接器(Link Editor)与它的工作-重定位 的由来.

### 重定位表
链接器在处理目标文件时, 对目标文件中引用外部函数或者变量的位置进行重定位, 即代码段和数据段中那些对绝对地址的引用的位置.
这些重定位的信息都记录在ELF文件的重定位表里面.
其实目标文件中, 除了.data, .text这些段外, 若用到了其他目标文件中的外部变量或者函数, 就会多了对应的重定位表.

假如.data用了外部的全局变量, 就会多了一个.reldata段记录了所引用的外部变量的地址偏移值(offset)以及在符号表中的下标等.
假如.text没有用了外部的全局变量, 就不会有.reltext段.

## 符号
在链接中, 我们将函数和变量统称为符号(Symbol), 函数名或变量名就是符号名(Symbol Name)., 每个目标文件都会有一个相应的符号表(Symbol Table),
这个表记录了目标文件中所有到的所有符号.
每个定义的符号都有一个对应的值, 叫做符号值(Symbol Value), 对于变量和函数而言, 符号值就是他们的地址.
使用 ``` nm hello.o``` 就可以查看hello.o里所有的符号.

### 符号修饰与函数签名
就C++而言, 为了实现重载这简单的一种情况, 编译器和链接器如何区分两个名字一样的函数呢?

为了支持这些情况, 人们发明了符号修饰(NAME Decoration)或符号改编(NAME Mangling).
编译器与链接器在处理符号时, 会把函数名, 命名空间, 参数类型, 所在的类等信息, 全部根据自己定的表翻译成一串符号, 自然就不会有相同.

### extern C
由此引出extern C的由来.
为什么C++用使用C代码的时候, 需要用```extern "C"```来当做C语言处理呢? C++兼容C, 直接用应该也没有问题吧?

原因就是上述的符号改编(NAME Mangling), 试想一下使用C中string.h里而不是C++中string的memset的时候, 
如果不限定```extern "C"```的时候, 就会进行符号改编从而使用了C++里string的memset, 使用```extern "C"```就不会进行符号改编从而链接到正确的C函数. C++编译器会在编译C++的程序时默认定义```_cplusplus```宏, 以下就是解决方法:

```
#ifdef __cplusplus
extern "C" {
#endif

void *memset(void *, int, size_t);

#ifdef __cpluplus
}
#endif
```

### 很多错误的根源-弱符号与强符号
对C/C++来说, 编译器默认函数和初始化了的全局变量为**强符号**, 未初始化的全局变量为**弱符号**.
我们也可以通过GCC的```__attribute__((weak))```来定义任何一个强符号为弱符号.

```
extern int ext;

int weak
int strong = 1;
__attribute__((weak)) weak2 = 2;
int main(void)
{
 return 0;
}
 
```

上面的这段程序中, weak和weak2是弱符号, strong 和main是强符号, ext既非强符号也非弱符号, 因为它是一个外部变量的引用.

有以下规则:

1.  不允许强符号被多次定义(即不同的目标文件中不能有同名的强符号)
        我们常见的报错:符号重定义错误就是链接器因此而报的.

2. 如果一个符号在某个目标文件中是强符号, 在其他文件中都是弱符号, 那么选择强符号.

```
 /* bar.c */
 int x;
 void f(){ x = 1314; }

 /* foo.c */
 #include <stdio.h>
 void f(void);
 int x = 777;
 int main(void)
{
 f();
 printf("x = %d\n", x);
 return 0;
}
```

这里输出的x是1314, 明显main里的x变量由777被改变成1314了.
因为foo.c中的x是强符号, 而bar.c中的x是弱符号, 所以bar.c中就使用了foo.c中的符号, 这会带来难以查找的错误.
在编译链接时, ```gcc foo.c bar.c```, 链接器不会表明它监测到多个x的定义.

---

```
 /* bar2.c */
 double x;
 void f() { x = -0.0; }

 /* foo2.c */
 #include <stdio.h>
 void f(void);
 int x = 1234;
 int y = 5678;
 int main()
{
 f();
 printf("x = 0x%x y = 0x%x \n", x, y);
 return 0;
}
```

这里, foo2.c中的x跟y都是强符号, 而bar2.c中的x是弱符号, 链接器选择了foo2.c中的x.
而在```bar2.c 中的 f函数中```赋值时, 就是给for2.c中的```int x```赋值.
在一台IA32机器上, double类型是8个字节, 而int类型是4个字节, 因此bar2.c的```x=-0.0```会覆盖了x跟y的位置.
(x跟y在foo2.c中占8个字节, 而在bar2.c中的强符号就占了8个字节, 执行f函数赋值为-0.0时就覆盖了x跟y的位置了)

在编译链接时, ```gcc foo.c bar.c```, 在Mac系统里, gcc和clang编译, 链接器ld会表明double x这个强符号替换了int x这个弱符号.
> ld: warning: tentative definition of '_x' with size 8 from '/var/folders/81/0q8j79597dldk23mm2svgpjc0000gn/T//cc79XQz8.o' is being replaced by real definition of smaller size 4 from '/var/folders/81/0q8j79597dldk23mm2svgpjc0000gn/T//ccBHUpu6.o'

3. 如果一个符号在所有的目标文件中都是弱符号, 那么选择其中占用空间最大的一个. 其实这个说法有两个, 选择最大空间的是程序员的自我修养的说法,
而CSAPP的说法是, 随机选择一个.
在这里, 我猜测是两者用词用所不同. 请往下看:

```
 /* weak2.c */
__attribute__((weak)) long double x;

 /* weak1.c */
 double x;

 /* main.c */
 #include <stdio.h>
 void f(void);
 int x;
 int main()
{
 x = 1314;
 return 0;
}
```

```gcc -c weak1.c weak2.c main.c``` 得到目标文件, 用```nm -S weak1.o```分别查看, 可以知道, main.c中的x占用4字节, weak1.c中的x占用8字节, 
weak2.c中x占用16字节.

```
➜ nm -S w1.o
0000000000000008 0000000000000008 C x

➜ nm -S w2.o
0000000000000010 0000000000000010 C x

➜ nm -S main.o
0000000000000000 0000000000000040 T main
                 U printf
0000000000000004 0000000000000004 C x
0000000000000008 0000000000000008 C y
```

最终链接后, 使用```readelf -s```或者```nm -S```查看:

```
➜ nm -S a.out
0000000000601040 B __bss_start
0000000000601040 0000000000000001 b completed.6973
0000000000601030 D __data_start
0000000000601030 W data_start
0000000000400470 t deregister_tm_clones
00000000004004e0 t __do_global_dtors_aux
0000000000600e18 t __do_global_dtors_aux_fini_array_entry
0000000000601038 D __dso_handle
0000000000600e28 d _DYNAMIC
0000000000601040 D _edata
0000000000601060 B _end
00000000004005e4 T _fini
0000000000400500 t frame_dummy
0000000000600e10 t __frame_dummy_init_array_entry
0000000000400730 r __FRAME_END__
0000000000601000 d _GLOBAL_OFFSET_TABLE_
                 w __gmon_start__
00000000004003e0 T _init
0000000000600e18 t __init_array_end
0000000000600e10 t __init_array_start
00000000004005f0 0000000000000004 R _IO_stdin_used
                 w _ITM_deregisterTMCloneTable
                 w _ITM_registerTMCloneTable
0000000000600e20 d __JCR_END__
0000000000600e20 d __JCR_LIST__
                 w _Jv_RegisterClasses
00000000004005e0 0000000000000002 T __libc_csu_fini
0000000000400570 0000000000000065 T __libc_csu_init
                 U __libc_start_main@@GLIBC_2.2.5
000000000040052d 0000000000000040 T main
                 U printf@@GLIBC_2.2.5
00000000004004a0 t register_tm_clones
0000000000400440 T _start
0000000000601040 D __TMC_END__
0000000000601050 0000000000000010 B x
0000000000601048 0000000000000008 B y


gcc version 4.8.4 (Ubuntu 4.8.4-2ubuntu1~14.04) 
```

可以看到, 最终的x是占用16字节的空间.

### 总结


尽量不要使用多个不同类型的弱符号.


## 参考资料
本文几乎可以算是对"Linux C一站式学习", "程序员的自我修养-链接装载与库"的归纳整理.
