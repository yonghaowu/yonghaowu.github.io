---
layout: post
title: Google Japan电面
description: 不过不失的电面, 努力刷题吧.
categories:
- 技术
tags:
- go
---

(原创, 第一次发表于: http://www.mitbbs.com/article_t/JobHunting/33208269.html)
国内大三下学生，投了Google Japan 求RP， 感觉是跪了。  
此外，求大神们内推，邮箱christopherwuy at gmail.com  
简介： C = Go > C++ = PHP > Python = R  

Contributor of WineHQ, had sent more than 50 patches about VC++ runtime(
msvcr/msvcp).  Some of them are the implementation of tr2::Filesystem 
Library, tests of tr2::Threads and implementation of complex istream and 
ostream::operator. 
See  http://goo.gl/Rn8eaW  
Accepted by Google Summer Of Code 2015, project is implementing Filesystem 
functions from tr2 namespace on Wine.  

我的简历在LinkedIn：https://www.linkedin.com/in/yonghaohu  

原题:https://leetcode.com/problems/wiggle-sort-ii/

一上来就是问题，可惜没有刷到这个题目, 一个数组，排序成这样x0 < x1 > x2 < x3 > < > <
然后我就分析，make sure understand the question，
然后说能不能用method like insertion sort， 他说make sense
然后我用插入排序的思想跑了一遍， 然后是可以work的
然后问我时间复杂度，我最好最坏平均都分析了：

```
best time: On
worst: On^2
time complexity: O(n^2)
n is the size of array
```

然后问我有没有办法优化。。我一直尝试用了几个方法，但是都不行，最后他举例子，
提示了一下

```
5 < 7 > 5 < 7 > 5 < 7 > 6  
```

然后排序后 ，提醒我有什么规律，我分析出最后两个数可以交换
然后他问我为什么可以交换成立
于是我重回一些例子，分析了一下，中间有一点跑偏了，我立马问他，what is our 
question.
然后他说， 是为什么交换可以成立有什么规律。
最后分析出了奇数，偶数下， 可以比较最后两个数，然后交换不
最后我说写pseducode， 他说好。
然后就写， 在写的时候已经比较正式，就是比较了是否为空数组，
而且swap可以不做用其他方法，等等
写完了他就说没有时间了，结束
伪代码是这样的：

```
if(nums.size())
    ....
vector<int> new_array;

new_aray.push_back(nums[0]);
if(size > 1) {
    if（num[1] > num[0])

        push_back(num[1]);

    else
        inserttobegin(num[1]);

}
    

for(int i=2;i<n； ++i)

{
    if(i%2 == 0) //i&1 {
        if(new_array[i-1] > a[i]) {
            puish_back(a[i]);

            swap(a[i-1], a[i]);
/*
int tmp = a[i-1]；

a[i-1] = a[i];

a[i] = tmp;

*/

}else {
        push_back(a[i];

}
}else {
    if(new_array[i-1] < a[i]) {
        push_bak(a[i];

    swap(a[i..);

}else{
    xx
}

}    
}
```
