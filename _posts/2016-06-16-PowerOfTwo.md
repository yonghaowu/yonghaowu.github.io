---
layout: post
title: PowerOfTwo
description: Given an integer, write a function to determine if it is a power of two.
categories:
- 技术
tags:
- C++
---

#231. Power of Two
##Question
Given an integer, write a function to determine if it is a power of two.

##Solution
###Approach #1 (count the number of 1) [Accepted]
####Algorithm
Integer is a power of two means only one bit of n is '1', for example,  ```100``` is    ```2^2=4``` while ```110``` is ```2^2+2^1=6```.


When n<=0, it can't be power of two as ```2^-1=0.5``` and because the parameter n is int, we can sure that it has only 32 bit, so we count the number of 1 in 32 bits to check whether only one bit of n is '1' when n is positive.


```
class Solution {
public:
    bool isPowerOfTwo(int n) {
        if(n<=0)
            return false;
        int nums_of_one = 0;
        for(int i=0; i<32; ++i) {
            nums_of_one += n&1;
            if(nums_of_one > 1)
                return false;
            n >>= 1;
        }
        return true;
    }
};
```

####Complexity Analysis

* Time complexity : O(1).
* Space complexity : O(1).

---
###Approach #2 (log2 in C++11) [Accepted]
####Algorithm

The result of log2(n) in math must be an interger instead of float when integer is a power of two, so we use log2() function in C++11 and check whether log2(n) is an interger by  difference between ```floor(log2(n))``` and ```ceil(log2(n))```. 

For example, n=5, ```log2(5)=2.19722```, ```floor(2.19722)=2```, ```ceil(2.19722)=3```, the difference is 1, so it is not power of two.

```
class Solution {
public:
    bool isPowerOfTwo(int n) {
        if(n<=0)
            return false;

        double tmp = log2(n);
        int a = floor(tmp);
        int b = ceil(tmp);
        if(b-a == 0)
            return true;
        return false;
    }
};
```

####Complexity Analysis

* Time complexity : O(1).
* Space complexity : O(1).

We can also use ```pow(2, log2(n))``` instead of ```floor(log2(n)) -  ceil(log2(n))```. 

```
class Solution {
public:
    bool isPowerOfTwo(int n) {
        if(!n)
            return false;

        int t = floor(log2(n));
        if(pow(2, t) == n)
            return true;
        return false;
    }
};
```

---

###Approach #3 (using n&(n-1) trick) [Accepted]
####Algorithm
I didn't come up with this, thanks for [dong.wang.1694's solution](https://leetcode.com/discuss/43875/using-n%26-n-1-trick).

We can know that power of 2 means only one bit of n is '1', for example, ```1```, ```10```, ```100``` etc, so n-1 means the other bits will become 1, e.g. ```0```, ```01```, ```011```. Power of 2 minus 1 means all of its digits will negate.  
Therefore, the result of ```n&(n-1)``` must be 0.

```
class Solution {
public:
    bool isPowerOfTwo(int n) {
        if(n<=0) return false;
        return !(n&(n-1));
    }
};
```

####Complexity Analysis

* Time complexity : O(1).
* Space complexity : O(1).
