---
layout: post
title: 用C实现JS里eval(“function(arg1, arg2)”)
description: 在C语言里, 如何通过输入函数名字来调用函数?
categories:
- 技术
tags:
- C++
---
在C语言里, 如何通过输入函数名字来调用函数?
[直接上代码](https://github.com/YongHaoWu/C_eval).

大致有三种方法:

1. 用函数字典, 缺点是代码耦合在一起, 无法复用.

```
#include <iostream>
#include <map>
#include <string>
#include <functional>

void foo() { std::cout << "foo()"; }
void boo() { std::cout << "boo()"; }
void too() { std::cout << "too()"; }
void goo() { std::cout << "goo()"; }

int main() {
  std::map<std::string, std::function<void()>> functions;
  functions["foo"] = foo;
  functions["boo"] = boo;
  functions["too"] = too;
  functions["goo"] = goo;

  std::string func;
  std::cin >> func;
  if (functions.find(func) != functions.end()) {
    functions[func]();
  }
  return 0;
}
```

2. 利用nm或者objdump, 在Makefile中在编译阶段将符号信息输出到源代码里. 缺点是每次在不同的环境里运行都要重新编译一次.

```
objs = main.o reflect.o

main: $(objs)
        gcc -o $@ $^
        nm $@ | awk 'BEGIN{ print "#include <stdio.h>"; print "#include \"reflect.h\""; print "struct sym_table_t gbl_sym_table[]={" } { if(NF==3){print "{\"" $$3 "\", (void*)0x" $$1 "},"}} END{print "{NULL,NULL} };"}' > .reflect.real.c
        gcc -c .reflect.real.c -o .reflect.real.o
        gcc -o $@ $^ .reflect.real.o
        nm $@ | awk 'BEGIN{ print "#include <stdio.h>"; print "#include \"reflect.h\""; print "struct sym_table_t gbl_sym_table[]={" } { if(NF==3){print "{\"" $$3 "\", (void*)0x" $$1 "},"}} END{print "{NULL,NULL} };"}' > .reflect.real.c
        gcc -c .reflect.real.c -o .reflect.real.o
        gcc -o $@ $^ .reflect.real.o
```

以上方法都可以在[Stackoverflow上找到](http://stackoverflow.com/questions/11254891/can-a-running-c-program-access-its-own-symbol-table?rq=1)

3. 直接到ELF里查符号表, [找出函数的名字与值](https://github.com/YongHaoWu/C_eval).

方法大致是, 读取编译后的程序(可执行文件也是ELF), 找到SHT_SYMTAB(符号表), 然后遍历符号表, 找到与函数名一样的符号. 

因为现在的C语言已经不会在符号前加上下划线了, 所以可以名字与符号名相同.
以及找到对应的value, 直接用函数指针保存, 使用即可.

```
void (*fun)(void) = (void*)sym.st_value;
(*fun)();
```

所有extern 函数的符号都会存在可执行文件中, 所以即便是多个模块的编译链接, 这个函数依然适用.

# ELF(Executable and Linking Format)
ELF(Executable and Linking Format)是一个开放标准, 各种UNIX系统的可执行文件都采用ELF格式, 它有四种不同的类型:

可重定位的目标文件(Relocatable, 或者Object File), Linux的.o, Windows的.obj
可执行文件(Executable), Linux的.out, Windows的.exe
共享库(Shared Object, 或者Shared Library), Linux的.so, Windows的.DLL
核心转储文件(Core Dump File)a, Linux下的core dump
