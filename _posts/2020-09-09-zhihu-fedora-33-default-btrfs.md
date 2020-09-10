---
layout: post
title:  "回答：如何看待 Fedora 33 将默认使用 btrfs 文件系统？"
comments: true
---

对应的[问题](https://www.zhihu.com/question/407386653).

先去看看 @醉卧沙场 的[回答](https://www.zhihu.com/question/407386653/answer/1354964606)，
特别是文中提到的那个[链接](https://fedoraproject.org/wiki/Changes/BtrfsByDefault#Detailed_Description)。
一般方案很保守，替换LVM到btrfs，`/boot`保持原样，这样grub启动的问题都不会太大。Ubuntu的zsys方案里面，
`/boot`做成了bpool,更加激进一点。opensuse的btrfs的子卷方案更加复杂

安装一个Fedora的时候，假设只有一个盘，那么如何划分这个盘是安装程序需要考虑的问题。
Linux下一般有两层划分，第一次是传统意义上的分区（partitions），Windows里面的`C:`盘之类的说的就是分区。
但是一直以来有个问题就是一旦设定了分区，在想修改分区就比较困难（并非不可能）。特别是老BIOS分区，
分为主分区和逻辑分区，这个调整起来更麻烦。为了解决这个问题，大部分服务器的操作系统（windows的非系统盘也支持）
都提供一种“存储卷”，也就是抽象出一个逻辑上的存储池，整个存储的地址空间不再是一维的。
基于存储卷的设计，Fedora首先把你的盘设置为一个pv（物理卷，实际的存储提供者），
然后再创建一个vg（卷组，逻辑上的存储池），然后在这个vg上面创建`/`和`/home`这样的逻辑卷lv,最后再将lv格式化为xfs或者ext4。
主要问题是，系统依然需要在lv依然是一个文件系统的，有自己确定的大小。如果用户不满意这个大小比例，
然后又给较大的分区（数据可能不太多）使用了优秀但是不能缩小的xfs系统，那么以后后悔了也很难改（只能再给vg加pv了）。

btrfs的设计不一样，它有一个子卷的概念（深入的探讨需要阅读fc大大的[文章](https://farseerfc.me/btrfs-vs-zfs-difference-in-implementing-snapshots.html))。
子卷是个完整的文件系统（有自己独立的inode）。如果Fedora采用btrfs作为`/`系统，那么`/home`之类的目录，可以变成一个子卷。
这个子卷是个独立的文件系统，但是不再需要一开始就确定大小，这些子卷共享一个存储池的同时，每个都有自己独立的文件系统。
这个基本上是最直观的好处。
当然，说到btrfs必须要提到bugs,这个是最让人诟病的。官方的wiki有个详尽的[表格](https://btrfs.wiki.kernel.org/index.php/Status#Overview)，
除了RAID56是明确不稳定的，一般都还好。当然另一个值得一看的wiki是Debian wiki的[btrfs页面](https://wiki.debian.org/Btrfs#Warnings)，里面提到了一些
5.x内核里的bug,不过总体来说可控。

我的nas用的Fedora 32，选择btrfs之后，系统盘就是这样的方案，目前一切都ok。另外nas上跑的虚拟机是debian 10，用btrfs RAID 1跑`/`和`/var`，
目前也一切正常。数据问题是大问题，一个是要多备份，二是如果觉得不安全，就不要用。Fedora是新技术试验场，风险一直都是存在的。
 