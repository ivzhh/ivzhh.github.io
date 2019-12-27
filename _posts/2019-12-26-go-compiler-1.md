---
layout: post
title:  "go 编译器分析（SSA）"
---

编译器在过去的几十年里层出不穷，一个重要的变革就是基于 SSA 的优化器。
其中最出名的自然是 LLVM 提供的 LLVM IR。一款工业级的编译器更加有助于


Go 编译器相关的文章不少了，有的关注整体编译流程[^2]，有的关注 Plan9 汇编[^3]，
有的对SSA这些内容进行了涉猎[^1]。特别是这篇[^1]对SSA的话题有一定的覆盖，


Go 在[2016年](https://github.com/golang/go/commit/a6fb2aede7c8d47b4d913eb83fa45bbeca76c433)将后端转向了SSA

[^1]: [Go 语言设计与实现](https://draveness.me/golang/docs/part1-prerequisite/ch02-compile/golang-ir-ssa/)

[^2]: [小米大佬讲解 Go 之编译器原理](https://mp.weixin.qq.com/s/M-gDOGY6oFfBRD8B3fU14w)

[^3]: [Go 系列文章3 ：plan9 汇编入门](https://xargin.com/plan9-assembly/)
