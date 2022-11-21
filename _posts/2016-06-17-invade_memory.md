---
layout: post
title: how to invade memory in C 
description: 如何通过C去侵略内存?
categories:
- 技术
tags:
- C++
---

Here is a simple example, what is the output of this program?

```
#include <iostream>
using namespace std;
int main()
{
    float f = 0.0;
    int i = 5;
    f = (float)i;
    cout<<f<<endl;
    f = *(float*)&i;
    cout<<f<<endl;
    return 0;
}
```

The first one is Implicit Conversion, signed integer to floating-point, theirs bits amount are equal(32), so f and i
have the same value, the result is 5.
While the second one ``` f = (float)i ``` means that the complier will interpret ```int i(0x0005)``` as ```float```, so f is 7.00649e-45

We can invade a struct's member using this tech.

```
#include <iostream>
using namespace std;

typedef struct _test{
    int a;
    int b;
    int c;
    double d;
} test;

int main()
{
    test real_struct;
    real_struct.a = 1;
    real_struct.b = 2;
    real_struct.c = 3;
    real_struct.d = 4.4;
    cout<<endl<<"Origin struct information: "<<endl;
    cout<<"int a:\t"<<(&real_struct.a)<<"\t";
    cout<<real_struct.a<<endl;
    cout<<"int b:\t"<<(&real_struct.b)<<"\t";
    cout<<real_struct.b<<endl;
    cout<<"int c:\t"<<(&real_struct.c)<<"\t";
    cout<<real_struct.c<<endl;
    cout<<"double d:\t"<<(&real_struct.d)<<"\t";
    cout<<real_struct.d<<endl;

    cout<<endl<<"now struct _test* invaid_struct = (test*)&(real_struct.b)"<<endl;
    struct _test* invaid_struct = (test*)&(real_struct.b);
    cout<<"\t((&(invaid_struct->a))-1) is "<<((&(invaid_struct->a))-1)<<endl;
    cout<<"\t((&(invaid_struct->a))-1) is "<<*(&(invaid_struct->a)-1)<<endl<<endl;
    cout<<"\t&(invaid_struct->a) is "<<&(invaid_struct->a)<<endl;
    cout<<"\t&(invaid_struct->a) is "<<invaid_struct->a<<endl<<endl;
    cout<<"\t&(invaid_struct->b) is "<<&(invaid_struct->b)<<endl;
    cout<<"\t(invaid_struct->b)  is "<<(invaid_struct->b)<<endl;
    cout<<"\t(double)(invaid_struct->b)  is "<<(double)(invaid_struct->b)<<endl<<endl;
    cout<<"\t&(invaid_struct->c) is "<<&(invaid_struct->c)<<endl;
    cout<<"\t(invaid_struct->c)  is "<<(invaid_struct->c)<<endl;
    cout<<"\t(double)(invaid_struct->c)  is "<<(double)(invaid_struct->c)<<endl;
    cout<<"\t&(invaid_struct->d) is "<<&(invaid_struct->d)<<endl;
    cout<<"\t(invaid_struct->d) is "<<(invaid_struct->d)<<endl;
    cout<<"\t(double)(invaid_struct->d)  is "<<(double)(invaid_struct->d)<<endl;
    return 0;
}
```

The output is 

```
Origin struct information:
int a:	0x7fff5091e640	1
int b:	0x7fff5091e644	2
int c:	0x7fff5091e648	3
double d:	0x7fff5091e650	4.4

now struct _test* invaid_struct = (test*)&(real_struct.b)
	((&(invaid_struct->a))-1) is 0x7fff5091e640
	((&(invaid_struct->a))-1) is 1

	&(invaid_struct->a) is 0x7fff5091e644
	&(invaid_struct->a) is 2

	&(invaid_struct->b) is 0x7fff5091e648
	(invaid_struct->b)  is 3
	(double)(invaid_struct->b)  is 3

	&(invaid_struct->c) is 0x7fff5091e64c
	(invaid_struct->c)  is 0
	(double)(invaid_struct->c)  is 0
	&(invaid_struct->d) is 0x7fff5091e654
	(invaid_struct->d) is 5.31069e-315
	(double)(invaid_struct->d)  is 5.31069e-315
```
