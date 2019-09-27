---
layout: post
title:  "自底向上的 Kubernetes Operator 解析"
---

## 背景

Kubernetes 的强项是部署无状态的项目（ stateless ），比如网页服务器。
但是很多软件是有状态的，比如需要访问磁盘，或者只能有一个实例，或者要有主从架构，
甚至是有备份方案等等。 Kubernetes 提供给用户的界面是声明式的，当年 SCIP 刚开始流行的时候，
声明式的“告诉我要什么，不要告诉我怎么做”是非常一种很冲击的观念。
函数式语言把这个功能交给了编译器去把“要什么”转换为“怎么做”，
Kubernetes 则把用户提交的 YAML SPEC 转换为调度的方案。
虽然 Kubernetes 提供了 StatefulSet 来表达<quote>“至多一个”保证的强一致单例</quote>[^1]，
但是这个方案的上限就是 Kubernetes 提供给 StatefulSet 的调度逻辑，
超过了这个范围， Kubernetes 就无所适从了。

Kubernetes Operator [^2]（以下简称 operator ）很聪明的提供了一种模式（ pattern ），
这个方式其实也是把 Kubernetes 内部调度器的工作方式暴露给应用开发者，
应用开发者可以定制自己的部署逻辑。当然，对于很多人来说，了解 Operator 的实现细节不是必须的，
但是对于涉及到存储（Storage）的应用，开发者很有必要去了解 Operator 的工作方式了。
Operator 是一种模式，实现这种模式有好几种方法。目前来说有三种，

1. 徒手写一个
2. 用 CoreOS 的 operator framework
3. 用 Kubebuilder （有 v1 和 v2 两个版本的API）

之所以会有方案2和3，是因为有很多重复的工作，所以2和3分别提供了自己的代码生成器
和库封装方案来解决这个问题。方案1单纯用来帮助理解 Operator 的底层到底是如何实现的；
方案2和3则有一个选择问题。当我开始写 operator 的时候，我花了不少时间去研究
到底用哪一个。后来在 reddit [^4] 和知乎 [^5] 上看到似乎大家更推荐 Kubebuilder ，而且
Awesome Operator [^3] 上的项目好多都用 Kubebuilder 写了，于是最后没再犹豫，
用 Kubebuilder 写了一个很简单的 operator。

## 动机

从一个新手的角度看待 operator 的时候，很多概念就算列举出来，也觉得隔了一层纱一样。
因此我并不是太推荐 v2 版的 Kubebuilder 的官方书 [^7]，那个 CronJob 的例子其实让我很费解。
反而我回头看了 v1 版 [^8]，觉得反而清晰多了。这也能看出，随着项目发展和封装程度提升，
基础概念也更多的被封装了。这个例子也不是孤立，比如 C 语言神书 The C Programming Language ，
初学者看起来莫名其妙，但是已经会 C 语言的人来看，感觉字字珠玑。
这个领域我觉得 CloudARK [^6] 的文章系列值得读，远好过 Kubebuilder 的文档。
当然他们的关于徒手写 operator 的文章 [^9] 也被 Kubernetes 官方收录了。
除了这一篇之外，还有两篇分别讨论 operator framework [^11] 和 Kubebuilder [^10] 结构的，
适合作为参考文章。 

本文的目标是趁着我还有新手角度的感觉（几周前刚开始写 Operator ），结合代码阅读，讨论下方案1和3，
也就是徒手方案和 Kubebuilder 方案。

## 基本结构

Kubernetes declarative spec 的核心是一堆 reconcile 循环，

```
for {
    if (当前状态 != 目标状态) {
        调整算法
    }
} 
```

Kubernetes 的 master 往往 CPU 和 内存占用都不低，一个原因是有很多
状态检测循环在运行。

当然这些循环也不是无脑循环， reconcile 只基于默写条件踩触发。



[^1]: [Serverless时代的Kubernetes工作负载：架构，平台和趋势](https://zhuanlan.zhihu.com/p/80688771?utm_source=ZHShareTargetIDMore&utm_medium=social&utm_oi=31361704394752)

[^2]: [Kubernetes API 与 Operator：不为人知的开发者战争（二）](http://dockone.io/article/8467)

[^3]: [Awesome Operators in the Wild](https://github.com/operator-framework/awesome-operators#awesome-operators-in-the-wild)

[^4]: [If I were to build an operator what should I use, operator-framework, Kubebuilder or start from scratch?](https://www.reddit.com/r/kubernetes/comments/8ien90/if_i_were_to_build_an_operator_what_should_i_use/dyrm1ot/)

[^5]: [如何看待Kubebuilder与Operator Framework(Operator SDK)](https://www.zhihu.com/question/290497164/answer/470306741)

[^6]: [cloudark](https://itnext.io/@cloudark)

[^7]: [The Kubebuilder Book](https://book.Kubebuilder.io/)

[^8]: [The Kubebuilder Book v1](https://book-v1.book.Kubebuilder.io/)

[^9]: [Writing Kubernetes Custom Controllers](https://medium.com/@cloudark/kubernetes-custom-controllers-b6c7d0668fdf)

[^10]: [Under the hood of Kubebuilder framework](https://itnext.io/under-the-hood-of-kubebuilder-framework-ff6b38c10796)

[^11]: [Under the hood of Operator SDK](https://itnext.io/under-the-hood-of-the-operator-sdk-eebc8fdeebbf)

[^20]: [进阶 K8s 高级玩家必备 | Kubebuilder：让编写 CRD 变得更简单](https://mp.weixin.qq.com/s/Gzpq71nCfSBc1uJw3dR7xA)
