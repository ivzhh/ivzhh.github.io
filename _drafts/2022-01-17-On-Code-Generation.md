---
layout: post
title:  "On Code Generation"
comments: true
---

In the old days, I was amazed by garbage collection system,
when I was still programming in C daily. My day job at that time is
to design pattern matching algorithm in C. In the code, there are
tons of creation of temporary objects with undetermined lifespan. 
The team cried for some fancier memory management tool. In the end,
I wrote a small GC library to handle that. However, the most painful
part of the library is code-generation. When you change the edges of the
graph of objects, you need to manually call `set_parent_to(child, parent)`
all the time. Of coursee, we get macros for that. Macros, a naive but
meanful code-generation, did save us tons of time.
Later I worked on a SIMD library in C++. My boss, a C++ guru and
metaprogramming master, designed a whole library based on templates and
macros. The only painful part is: you need to write specialized versions
of ray tracing in macros. Macros' magic reached its limit.

Paul Graham talked a lot about Lisp in "Hackers & Painters": it is
a language with uniform representation of code and data. Lisp enables you
generating code from code easily: it is an AST by default and a Lisp macro
can easily match a tree of shape and transform the matched nodes into
a new form. Rust can do that too: PyO3 works like magic 