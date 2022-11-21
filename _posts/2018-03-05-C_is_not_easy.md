---
layout: post
title: C 语言没有你想象中容易
description: C 语言只是学语法,当然简单.但是背后是涉及到编译链接,计算机原理等等.这些才是学C 语言必须要掌握的内容.
categories:
- 技术
tags:
- go
---

```
/* #include <stdio.h> */
/* #include <malloc.h> */
int main(){
    char *c = malloc(10);
    c[0] = 'a';
    printf("hi, ");
    printf("%s\n", c);
    free(c);
    return 0;
}
```
 为什么这个程序缺了头文件, 依然可以正常编译运行, 并且有正确的结果?

---

 ```
/* #include <stdio.h> */
/* #include <malloc.h> */
/* #include <assert.h> */
int main(){
    char *c = malloc(10);
    c[0] = 'a';
    printf("hi, ");
    printf("%s\n", c);
    assert(c[0] >= 0.0);
    free(c);
    return 0;
}
 ```

为啥这个程序, 加了 assert 又不行了呢?

---

1. #include 只是把头文件引入进来， 头文件的作用是 包含函数的原型。
2. linker（链接器）在链接这一步时，会根据头文件函数的原型去找. o 文件中的函数，然后链接进来
3. 对于找不到的函数，各个编译器处理会有不同。gcc、clang 会推断这个函数的原型，如 printf 就是 void printf(char \*c, char)
4. 推断了原型后，因为每个 C 程序都默认会链接 stdlib 库（gcc 编译里有nostdlib 选项,即不去默认链接 stdlib 的库），所以你正确的使用这个 C 语言函数，也是会找到对应的正确函数
5. 所以程序编译时会有警告，依然编译通过，并且能正确运行。


那为什么 assert 就不行了呢？
因为 assert 是一个宏，而不是函数，所以编译器不会像上述那样去处理。当没有引入 assert.h, 编译器便当它是函数来处理，最终 stdlib 里也找不到 assert 这个函数，就报错了。
