---
layout: post
title:  "自底向上的 Kubernetes Operator 解析"
---

Kubernetes的强项是部署无状态的项目（stateless），比如网页服务器。
但是很多软件是有状态的，比如需要访问磁盘，或者只能有一个实例，或者要有主从架构，
甚至是有备份方案等等。Kubernetes提供给用户的界面是声明式的，当年SCIP刚开始流行的时候，
声明式的“告诉我要什么，不要告诉我怎么做”是非常一种很冲击的观念。
函数式语言把这个功能交给了编译器去把“要什么”转换为“怎么做”，
Kubernetes则把用户提交的YAML SPEC转换为调度的方案。
虽然Kubernetes提供了StatefulSet来表达<quote>“至多一个”保证的强一致单例</quote>[^1]，
但是这个方案的上限就是Kubernetes提供给StatefulSet的调度逻辑，
超过了这个范围，Kubernetes就无所适从了。
Kubernetes Operator [^2]（以下简称operator）现在已经很常见了，

[^1]: [Serverless时代的Kubernetes工作负载：架构，平台和趋势](https://zhuanlan.zhihu.com/p/80688771?utm_source=ZHShareTargetIDMore&utm_medium=social&utm_oi=31361704394752)

[^2]: [Kubernetes API 与 Operator：不为人知的开发者战争（二）](http://dockone.io/article/8467)
