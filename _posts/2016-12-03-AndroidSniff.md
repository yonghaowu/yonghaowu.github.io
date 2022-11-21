---
layout: post
title: 实现安卓流量数据采集与标记
description: 
categories:
- 技术
tags:
- go
---

## 准备工作：

1.学习java以及安卓开发，我读了JAVA核心技术和第一行代码 
2. 利用PackageManager管理器，检索所有的应用程序与数据目.再用ActivityManager与PackagesInfo获取从上得到的所有app名称以及pid，并且使用listview布局展示出来。 
3. 我们可以在proc/(pid)/tcp或者udp这些文件夹中得到socket的信息,得到的信息如下：
```

    46: 010310AC:9C4C 030310AC:1770 01 
   |      |      |      |      |   |--> connection state
   |      |      |      |      |------> remote TCP port number
   |      |      |      |-------------> remote IPv4 address
   |      |      |--------------------> local TCP port number
   |      |---------------------------> local IPv4 address
   |----------------------------------> number of entry
   00000150:00000000 01:00000019 00000000  
      |        |     |     |       |--> number of unrecovered RTO timeouts
      |        |     |     |----------> number of jiffies until timer expires
      |        |     |----------------> timer_active (see below)
      |        |----------------------> receive-queue
      |-------------------------------> transmit-queue
   1000        0 54165785 4 cd1e6040 25 4 27 3 -1
    |          |    |     |    |     |  | |  | |--> slow start size threshold, 
    |          |    |     |    |     |  | |  |      or -1 if the threshold
    |          |    |     |    |     |  | |  |      is >= 0xFFFF
    |          |    |     |    |     |  | |  |----> sending congestion window
    |          |    |     |    |     |  | |-------> (ack.quick<<1)|ack.pingpong
    |          |    |     |    |     |  |---------> Predicted tick of soft clock
    |          |    |     |    |     |              (delayed ACK control data)
    |          |    |     |    |     |------------> retransmit timeout
    |          |    |     |    |------------------> location of socket in memory
    |          |    |     |-----------------------> socket reference count
    |          |    |--------------------G---------> inode
    |          |----------------------------------> unanswered 0-window probes
    |---------------------------------------------> uid
    
```
里面并没有pid的信息，无法将程序与socket对应。但是有inode的信息，根据inode，在linux中我们到/proc/(pid)/fd，使用如下命令即可查看对应的socket(inode)

```
ls -l /proc/7266/fd
total 0
lrwx------ 1 gavinb gavinb 64 2009-12-31 09:10 0 -> /dev/pts/1
lrwx------ 1 gavinb gavinb 64 2009-12-31 09:10 1 -> /dev/pts/1
lrwx------ 1 gavinb gavinb 64 2009-12-31 09:10 2 -> /dev/pts/1
lrwx------ 1 gavinb gavinb 64 2009-12-31 09:10 3 -> socket:[26442]
```

因为在fd里的都是链接，需要使用readlink函数。 
可是android及java均没有提供，我们需要使用NDK，使用c语言来解析/proc/(pid)/fd的内容，找到对应的socket，就可以将pid与socket对应起来。

目前我已经完成了对/proc/(pid)/socket的解析，正在下载sdk，准备完成对fd的解析并将pid与socket对应, 也就是找到与app对应的socket并且不需要root， 难点已经攻克。

##第二部分
继上述思路，发现使用readlink是需要root权限的，并且对/proc/"mypid"/fd这个目录使用api ``` dir.listFiles();```并不能获取文件，可能因为里面的都是linux下的链接。

因此，我暂时放弃上述思路，寻找其他方法。发现以下方法：

1.使用```runTime.exec(cmd);```可以在android里运行cmd的命令，所以可以通过这个来获取运行命令后的结果输出。因此可以考虑：

 * lsof ，但是这个命令在android里因为权限问题（就算是已经root）都会提示没有权限用readlink等。http://my.oschina.net/leejun2005/blog/153584
 * 在linux中可以使用netstat命令查看, 但是Android自带netstat命令不支持p参数, 所以无法查出pid(http://410063005.iteye.com/blog/1923543); 也没法像linux一样输出pid/program name，因此也不适合

2.另外的方法是使用uid来匹配程序 http://superuser.com/questions/627391/how-to-use-netstat-to-show-what-process-is-listening-on-a-port
但是可能会有相同uid的程序（同一厂商）

3.使用netlink命令，可是在最新版本的anroid已经不支持此命令 https://stackoverflow.com/questions/27148536/netlink-implementation-for-the-android-ndk

4.在ndk中使用c语言来遍历文件夹，读取软链接。依然存在问题，在java里还是NDK里执行su命令，然后再使用ndk，在里面的c语言里使用readdir,都提示没有权限。

------------------------------

##第三部分
目前以上方法中，最终得出一个暂时可行的办法
使用 ``` ls -l /proc/(pid)/fd > /sdcard/fdres```，再使用```cat /sdcard/fdres```



#pacp
1.使用jNetPcapcap
http://jnetpcap.com/?q=examples/classic
http://jnetpcap.com/?q=node/621
http://jnetpcap.com/docs/javadocs/jnetpcap-1.4/index.html

当需要同时抓取pcap跟摘要信息时，双线程同时运行，以秒为单位。
现在在配置.so到android studio


http://www.cpplive.com/html/1827.html
http://aswang.iteye.com/blog/1036305
将ndk-build命令加入到环境变量中：
Mac OS X下在~/.bash_profile（Linux下在~/.bashrc）文件尾部加入一行“export PATH=$PATH:XXX/android-ndk-r8e”后保存，如果该文件不存在则新建一个，由于该文件是隐藏文件，建议在终端中使用vi来编辑它。
3、关闭终端再打开让上一步设置的环境变量生效。
4、在终端中执行如下命令：
cd XXX/android-ndk-r8e/samples/hello-jni/jni（注意这里的XXX用2.1中的解压目录替代）  
ndk-build  
这实际是一个编译so文件的例子，它将hello-jni.c编译成so文件存放在”XXX/android-ndk-r8e/samples/hello-jni/libs/armeabi/”目录下。
5、编译我们自己的so文件
根据需要，修改XXX/android-ndk-r8e/samples/hello-jni/jni下的Android.mk文件，比我的Android.mk如下：
LOCAL_PATH := $(call my-dir)  
include $(CLEAR_VARS)  
LOCAL_MODULE    := usdk_android  
LOCAL_SRC_FILES := \  
    uSDK.c \  
    uwt.c \  
    common.c \  
    jni.c \  
LOCAL_LDLIBS     := -lm -llog  
其含义是告诉ndk-build，我要将当前Android.mk所在目录下的uSDK.c、uwt.c、common.c、 jni.c编译成so文件并将其命名为usdk_android.so，同时告诉ndk-build编译过程依赖标准数学库m跟Android日志库log。



A. tcpdump+Java解析

使用tcpdump（安卓系统底层的Linux工具）抓取网络数据，并转存到文件中，使用Java文件操作方法解析这个文件，并展示到用户界面上。这是我们所采用的方案，将在后面具体说明。

B. tcpdump+Jpcap解析

使用tcpdump抓取网络数据，并转存到网络中，而根据tcpdump转存文件是libpcap文件格式特点，使用libpcap的Java实现jpcap（或jnetpcap，下面统称jpcap）进行解析。这个方案和上面的方案相比，优点是不用自己实现文件解析的类了。缺点是在Android上在这个作业中，我们需要调用到的jpcap相关的方法是很有限的，但是却要包含一系列完整的jar文件，无意是增大了最终程序的大小，对于手机这种资源敏感的设备，这样做的代价太大。同时原本是为桌面平台开发的jpcap向Android平台移植（部分代码需要交叉编译），难度虽然不是很大，但是存在一定的不确定性。


三、使用Android NDK编译可执行程序
1、订制工具链
cd XXX/android-ndk-r8e/  
./build/tools/make-standalone-toolchain.sh --system=darwin-x86_64 （64位的Mac OS X）  
./build/tools/make-standalone-toolchain.sh --system=darwin-x86 （32位的Linux）  
（当然还有几个参数可以指定，如–platform用来指定平台，可以使用–help来查看帮助，这里就不深究了）
比如我执行命令的输出如下：
TrevortekiMacBook-Air:android-ndk-r8e Trevor$ ./build/tools/make-standalone-toolchain.sh --system=darwin-x86_64  
Auto-config: --toolchain=arm-linux-androideabi-4.6  
Copying prebuilt binaries...  
Copying sysroot headers and libraries...  
Copying libstdc++ headers and libraries...  
Creating package file: /tmp/ndk-Trevor/arm-linux-androideabi-4.6.tar.bz2  
Cleaning up...  
Done.  
TrevortekiMacBook-Air:android-ndk-r8e Trevor$  
上述命令的输出结果告诉我订制好的工具链所在位置为 /tmp/ndk-Trevor/arm-linux-androideabi-4.6.tar.bz2 ，其中Trevor是我系统的用户名，同理，大家可以根据输出来找到工具链所在位置。
2、解压工具链
将上一步得到的arm-linux-androideabi-4.6.tar.bz2解压到任意目录（建议使用用户Home目录，下文我们用”YYY”代指该目录，比如我的是家目录/Users/Trevor/）。
3、将工具链加入到环境变量中：
参见2.2，编辑Mac OS X下的~/.bash_profile或Linux下的~/.bashrc文件，在文件尾部加入一行“export PATH=$PATH:/YYY/arm-linux-androideabi-4.6/bin”后保存。
4、关闭终端再打开让上一步设置的环境变量生效。
5、测试
编写一个hello.c然后执行如下命令
arm-linux-androideabi-gcc hello.c -o hello  
得到一个ARM平台的可执行文件hello，使用adb命令将其push到Android系统的/data/目录下， 在Android后台执行该hello程序，不出意外的话，经典的“Hello World!”便在Android系统上得到了输出。
6、同理，编译多文件的可执行程序，只要将Makefile中的gcc使用上一步的arm-linux-androideabi-gcc替换，编译出来的便是基于Android ARM 平台的可执行文件。



要运行打包的二进制,需要把它放在/data目录

lsof + c<num> num为0显示命令所有的名称; 不为0表示按该值截断
通过pid查看pid目录下的cmdline来得到
保存的格式如下：
system_server   IPv6 TCP 192.168.1.2 49872 42.62.94.142 80 (CLOSE_WAIT)
没有 /etc/passwd 文件啦。你 2>/dev/null 就好

lsof -i  > /data/data/com.example.yonghaohu.sniff/files/tempres

在lsofres文件中，现在还没有时间戳，请添加上每条socket的时间戳，可以是采集到socket记录的系统时间

ApplicationName  IPType  Protocol SrcIp SrcPort DstIP DstPort Stat firsttime duration endtime
system_server  IPv6  TCP  192.168.1.2  49872  42.62.94.142  80 CLOSE_WAIT firsttime duration endtime

ctPf
c指command
t指IP类型
p指process ID
P指TCP还是UDP
n指结点名称
f指状态

1. lsof  每隔1秒运行  lsof -i -F ctPf >> lsof.txt, 按输入的时间间隔循环, 运行完后在再把当前的时间戳输入到文件后面. (date +%s > lsof.txt [平均0.8秒执行完lsof]
2. tcpdump, 运行tcpdump -t 2 -v -s 0 -w tcpdump.txt (-i any -p 要保留吗)
3. 最后, 根据时间戳,五元组整合在一起(运行tcpdump -r -v tcpdump.txt)
4. 根据算法组流

G 在监视文件/进程时会非常实用.
