---
layout: post
title: 实现sprintf--浮点数打印字符串
description:
-  亲爱的程序猿们，你们肯定都用过printf吧？你们知道，看起来理所当然的简单的printf，实际上是个难倒众多计算机科学家的难题吗？直到1971年，才有我们的毒师Mr.White科学家(Jon White)解决这个问题，直到1990年，我们的Mr.White才正式发表这算法的最终版本，Dragon4,
categories:
- 技术
tags:
- C++
---
  
>  亲爱的程序猿们，你们肯定都用过printf吧？你们知道，看起来理所当然的简单的printf，实际上是个难倒众多计算机科学家的难题吗？直到1971年，才有我们的毒师Mr.White科学家(Jon White)解决这个问题，直到1990年，我们的Mr.White才正式发表这算法的最终版本，Dragon4,
>  在随后到最近的几十年来，语言上的各种浮点数打印字符串都是用Dragon4算法，其他人的研究都只是对这个算法修修补补，直到Grisu算法的出现。Grisu算法由Florian Loitsch发表，64位的浮点数可以用它表示，但是有0.6%的依然要用Dragon4算法来表示。
>  因此，要是想做轮子，无论如何都要懂Dragon4算法！！！          ————引言
  
  为了修复我在wine中发现的bug--[sprintf在vs和gcc下的行为不一致](https://bugs.winehq.org/show_bug.cgi?id=37913),gcc的printf，sprintf是四舍六入五成双的舍入(银行家舍入)，而vs的则是四舍五入,开始研究起浮点数打印字符串。
  算法的核心就是把小数点后面的每一个数字提取出来,我分别想到2种方法：对于double a
  
  1. a - (int)a 这样把小数拿出来，乘以精度，得到的数值用round函数后，就是整数，接下来就容易了。可以参考[我的实现](https://github.com/YongHaoWu/algorithm_and_datastruct/blob/master/algorithms/my_sprintf.c),在精度不大的情况下没有问题。
  可是，在乘以精度的时候就会有问题，因为浮点数不可以精确表示。比如2.34以35位精度表示成2.3400000...000,当乘以超过一定精度的时候，你就会发现，小数点后不是单纯的0而是其他数字了。
  
  2. a- (int)a 这样把小数拿出来，用fmod(a, 0.1)取余数，可是问题是，0.789不断除0.1后,
  
  
  ```

      double temp = float_val;
      while(temp != 0) {
          cout<<"int   "<<(int)(temp*10)<<endl;
          temp = fmod(temp, 0.1);
          cout<<"float_val   "<<temp<<endl;
          cout<<"float_val*10=  "<<temp*10<<endl;
          temp *= 10.0;
      }
  ```
  
      运行结果：
      cin val
      0.789
      float_val   0.789

      int   7
      float_val   0.089
      float_val*10=  0.89
      1
      int   8
      float_val   0.09
      float_val*10=  0.9
      1
      int   8
      float_val   0.1
      float_val*10=  1
      1
      int   9
      float_val   0.1
      float_val*10=  1


问题就在最后0.09变成0.9后，除0.1再取小数就变0.1了。尝试好几种方法，无法解决。
最后只可以上网查资料,发现这个问题竟然是持续几十年的难题.
要是我无意中完美解决了，就像高斯一样了XD
  下一篇，是我翻译别人的文章, 讲解了Dragon4的背景知识。
