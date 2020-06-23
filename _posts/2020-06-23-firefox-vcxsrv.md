---
layout: post
title:  "Read Medium on Firefox over X11"
---

I run a Windows and a Ubuntu in Hyper-V on daily basis. 
All X11 apps are run by VcXsrv. Okular, VS Code, etc. are all as good as local apps.
Firefox works on 99% of websites I visit, but not on Medium main page.
I read Medium a lot as they have good articles on go, docker and k8s.
That page is highly dynamic, contents are loaded on-the-fly. Firefox will hang and
not respond even after a few minutes.

Luckily, I found a [solution](https://unix.stackexchange.com/questions/187415/why-is-firefox-so-slow-over-ssh\#comment1109574_187415) today.
There are two issues here:

* Some hard coded functions that only look for `localhost:0`. The solution is to use `--no-remote`.
* XRender is not enabled. The solution is to use `gfx.xrender.enabled = true` in `about:config` page.

