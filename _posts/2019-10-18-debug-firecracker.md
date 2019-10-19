---
layout: post
title:  "Debug ext4-related firecracker slowness"
---

# Intro

When I tried to play with firecracker from Amazon,
I met problem at step 1. Step 1 is to run a containerd with firecracker's plugin, a naive snapshotter and `ctr pull`.
`ctr pull` is responsible to download a debian latest docker image,
and use `unpigz` to `un-gz` it (ignore the steps after that).
However, I noticed that `ctr pull` performs **extremely slowly**.
The slowness is 22 minutes for un-gz this 45MiB file.
I tried to replace `unpigz` with normal `gzip` in the go source code;
and I also tried to use `tee` to observe what's going on. 
In the end, the conclusion is the slowness happens in `pipe` writing.
I switched to normal containerd for test and wrote a small
C problem using epoll to test, the uncompressing takes around 1 sec
to finish on my old machine.

# Search

I try to search the bug in firecracker, firecracker-containerd,
containerd and golang's issues. The closest report is 
[this issue on github](https://github.com/golang/go/issues/30957).
(maybe [this one too](https://github.com/golang/go/issues/9307))
During my debugging, go 1.12.6 was released, so I use gvm to install
it from source code. However, the problem persists.
I feel lucky because one of the worst thing a programmer can meet is
non-reproducible bug. I am happy this bug is not covered somehow.

# Learn

Before the debugging, I only wrote 2 to 3 hundreds lines of go code.
I learned how to use `trace` and `pprof` and it is obvious that
the problem is about the system wait. Then I moved to learn netpoll
and happily understand how go handles blocking syscalls.

# Strace

Now that the problem is about syscalls, so it is time for `strace`.
(Remember to use `-f` for threads and child processes, 
`-tt` for micro-second logging; use ruby to change timestamp to `sec:milli-sec` format, we only care milli second accuracy; also filter out all unpigz pids)
According to the strace, firecracker-containerd writes to `fd 13`
and unpigz reads `fd 12`; then unpigz outputs to `fd 15`, 
firecracker-containerd reads uncompressed from `fd 14`.

Let's look at one sample log:

	[pid 11419] 17.688 epoll_pwait(4,  <unfinished ...>
	[pid 11412] 17.688 epoll_pwait(4,  <unfinished ...>
	[pid 11419] 17.688 <... epoll_pwait resumed> [], 128, 0, NULL, 0) = 0 <0.000029>
	[pid 11412] 17.688 <... epoll_pwait resumed> [], 128, 0, NULL, 824635583980) = 0 <0.000031>
	[pid 11419] 17.688 epoll_pwait(4,  <unfinished ...>
	[pid 11412] 17.688 futex(0xc0000fc148, FUTEX_WAIT_PRIVATE, 0, NULL <unfinished ...>
	[pid 11410] 17.688 pread64(11,  <unfinished ...>
	[pid 11410] 17.688 <... pread64 resumed> "\261\225\\^\211BE\214\22\1\364\334KC\363\264\352;{`\327T\246\27t\333\276\274\274\22]\200"..., 32768, 163840) = 32768 <0.000119>
	[pid 11408] 17.688 <... nanosleep resumed> NULL) = 0 <0.000745>
	[pid 11410] 17.688 write(13, "\261\225\\^\211BE\214\22\1\364\334KC\363\264\352;{`\327T\246\27t\333\276\274\274\22]\200"..., 32768 <unfinished ...>
	[pid 11419] 17.688 <... epoll_pwait resumed> [{EPOLLOUT, {u32=2455682008, u64=139889540512728}}], 128, -1, NULL, 3) = 1 <0.000278>
	[pid 11410] 17.688 <... write resumed> ) = 32768 <0.000076>
	[pid 11419] 17.688 epoll_pwait(4,  <unfinished ...>
	[pid 11410] 17.688 pread64(11,  <unfinished ...>
	[pid 11410] 17.688 <... pread64 resumed> "\225\2675\322\335\267\320\267\226\301[\rT\"\212\27Y8ez\273\7\245L?f%b\220\6\347\320"..., 32768, 196608) = 32768 <0.000021>
	[pid 11408] 17.689 nanosleep({tv_sec=0, tv_nsec=20000},  <unfinished ...>
	[pid 11410] 17.689 write(13, "\225\2675\322\335\267\320\267\226\301[\rT\"\212\27Y8ez\273\7\245L?f%b\220\6\347\320"..., 32768) = -1 EAGAIN (Resource temporarily unavailable) <0.000011>
	[pid 11410] 17.689 futex(0xc000056bc8, FUTEX_WAIT_PRIVATE, 0, NULL <unfinished ...>

* Two threads are querying epoll `fd 4`
* Before "17.689, `write(13...`" finishing, `epoll_pwait` from `pid 11419` already returns one `EPOLLOUT`
* At 17.689, `write(13...` receives `EAGAIN`, then this `gr 111` (while using `delve`, it is goroutine 111; let's use `gr 111` for short) goes to `gopark`

Then the next time `epoll_pwait` is executed is 300 ms later:

	[pid 11414] 17.885 read(14,  <unfinished ...>
	[pid 11410] 17.885 futex(0xc0000fc148, FUTEX_WAKE_PRIVATE, 1 <unfinished ...>
	[pid 11419] 17.885 <... epoll_pwait resumed> [{EPOLLIN, {u32=2455681800, u64=139889540512520}}], 128, -1, NULL, 3) = 1 <0.197555>
	[pid 11414] 17.886 <... read resumed> "`\1E\0\0\0\0\0\21\0\0\0\0\0\0\0\326\10\0\0\22\0\16\0@\224J\0\0\0\0\0"..., 32768) = 32768 <0.001235>
	[pid 11419] 17.886 epoll_pwait(4,  <unfinished ...>
	[pid 11412] 17.886 <... futex resumed> ) = 0 <0.198004>
	[pid 11419] 17.886 <... epoll_pwait resumed> [{EPOLLIN, {u32=2455681800, u64=139889540512520}}], 128, -1, NULL, 3) = 1 <0.000066>
	[pid 11412] 17.886 futex(0xc0000fc148, FUTEX_WAIT_PRIVATE, 0, NULL <unfinished ...>
	[pid 11419] 17.886 epoll_pwait(4,  <unfinished ...>
	
	...
	
	[pid 11419] 17.995 epoll_pwait(4,  <unfinished ...>
	[pid 11414] 17.995 futex(0xc0000579c8, FUTEX_WAIT_PRIVATE, 0, NULL <unfinished ...>
	[pid 11408] 17.995 <... nanosleep resumed> NULL) = 0 <0.000659>
	[pid 11408] 17.995 nanosleep({tv_sec=0, tv_nsec=20000},  <unfinished ...>
	[pid 11408] 17.996 <... nanosleep resumed> NULL) = 0 <0.000447>
	[pid 11408] 17.996 nanosleep({tv_sec=0, tv_nsec=20000},  <unfinished ...>
	[pid 11408] 17.996 <... nanosleep resumed> NULL) = 0 <0.000505>
	[pid 11419] 17.997 <... epoll_pwait resumed> [{EPOLLOUT, {u32=2455682008, u64=139889540512728}}], 128, -1, NULL, 3) = 1 <0.002014>
	[pid 11419] 17.997 write(13, "\225\2675\322\335\267\320\267\226\301[\rT\"\212\27Y8ez\273\7\245L?f%b\220\6\347\320"..., 32768 <unfinished ...>
	[pid 11419] 17.997 <... write resumed> ) = 32768 <0.000037>

If this is a normal case, then 45MiB will take `45 * 1024 / 32 * 03 / 60 == 7.2 min` to finish copying. So my guess is the race condition cause netpoll missing the `epoll` as it is edge-triggerd.

	[pid 11444] 17.630 epoll_ctl(4, EPOLL_CTL_ADD, 13, {EPOLLIN|EPOLLOUT|EPOLLRDHUP|EPOLLET, {u32=2455682008, u64=139889540512728}}) = 0 <0.000028>
	
# Dive further

Later, I did a statistics on the corresponding timestamp of `write(13`,
to my surprise, the biggest gap is 21s. It means for 21 seconds,
there is no write to the `unpigz`. The read end of the pipe, 
which is `fd 12` before being `dup2` to `fd 0` in `unpigz`, is closed
and reused as:

	[pid 11414] 17.793 openat(AT_FDCWD, "/var/lib/firecracker-containerd/containerd/tmpmounts/containerd-mount736512679/bin/bash", O_WRONLY|O_CREAT|O_TRUNC|O_CLOEXEC, 0755 <unfinished ...>
	
	...
	
	[pid 11414] 17.874 <... openat resumed> ) = 12 <0.090660>
	
The `fd 12` is used repeatedly to construct file system: `/var/lib/firecracker-containerd/containerd/tmpmounts/containerd-mount736512679/`. 
It is closed and reopened for each file in the tmpmounts,
as the `untar` is being invoked.
During the gap of 21 seconds, there are dozens of `write(12` being 
invoked.

The gap now seems to be caused by epoll. Look at the strace log below:

	Line 24663: [pid 11419] 53.859 <... epoll_pwait resumed> [{EPOLLOUT, {u32=2455682008, u64=139889540512728}}], 128, -1, NULL, 3) = 1 <0.000615>
	Line 24675: [pid 11419] 53.860 epoll_pwait(4,  <unfinished ...>
	Line 24677: [pid 11419] 53.860 <... epoll_pwait resumed> [], 128, 0, NULL, 0) = 0 <0.000034>
	Line 24680: [pid 11419] 53.860 epoll_pwait(4,  <unfinished ...>
	Line 27527: [pid 11419] 57.568 <... epoll_pwait resumed> [{EPOLLIN, {u32=2455681800, u64=139889540512520}}], 128, -1, NULL, 3) = 1 <3.708379>
	Line 27528: [pid 11419] 57.569 epoll_pwait(4,  <unfinished ...>
	Line 28803: [pid 11419] 59.477 <... epoll_pwait resumed> [{EPOLLIN, {u32=2455681800, u64=139889540512520}}], 128, -1, NULL, 3) = 1 <1.908844>
	Line 28804: [pid 11419] 59.477 epoll_pwait(4,  <unfinished ...>
	Line 28805: [pid 11419] 59.477 <... epoll_pwait resumed> [{EPOLLIN, {u32=2455681800, u64=139889540512520}}], 128, -1, NULL, 3) = 1 <0.000035>
	Line 28806: [pid 11419] 59.478 epoll_pwait(4,  <unfinished ...>
	Line 32225: [pid 11419] 03.809 <... epoll_pwait resumed> [{EPOLLIN, {u32=2455681800, u64=139889540512520}}], 128, -1, NULL, 3) = 1 <4.331551>
	Line 32226: [pid 11419] 03.809 epoll_pwait(4,  <unfinished ...>
	Line 35270: [pid 11419] 07.619 <... epoll_pwait resumed> [{EPOLLIN, {u32=2455681800, u64=139889540512520}}], 128, -1, NULL, 3) = 1 <3.809758>
	Line 35278: [pid 11419] 07.620 epoll_pwait(4,  <unfinished ...>
	Line 38096: [pid 11419] 11.281 <... epoll_pwait resumed> [{EPOLLIN, {u32=2455681800, u64=139889540512520}}], 128, -1, NULL, 3) = 1 <3.660940>
	Line 38098: [pid 11419] 11.281 epoll_pwait(4,  <unfinished ...>
	Line 38100: [pid 11419] 11.281 <... epoll_pwait resumed> [{EPOLLIN, {u32=2455681800, u64=139889540512520}}], 128, -1, NULL, 3) = 1 <0.000031>
	Line 38102: [pid 11419] 11.281 epoll_pwait(4,  <unfinished ...>
	Line 41242: [pid 11419] 15.196 <... epoll_pwait resumed> [{EPOLLIN, {u32=2455681800, u64=139889540512520}}, {EPOLLOUT, {u32=2455682008, u64=139889540512728}}], 128, -1, NULL, 3) = 2 <3.915028>
	Line 41252: [pid 11419] 15.196 epoll_pwait(4, [], 128, 0, NULL, 0) = 0 <0.000010>
	
After 21 second, `EPOLLOUT` becomes available again!!! What's going on?
It is just stdin!!!

# Truth

I go back and read the `runtime/proc.go`, it turns out that those systecall `nanosleep()`
are caused by `usleep()` in `sysmon`. There are three active threads (`M`):

0. `write` and `epoll_pwait` on the pipes
1. `openat` and `write` to loopback device (`/dev/loop2 on /var/lib/firecracker-containerd/containerd/tmpmounts/containerd-mount736512679 type ext4 (rw,relatime,sync,dirsync)`)
2. `read` from `unpigz` and `tee` to untar

Because step 1 is very slow (naive snapshotter), so step 0, 2 and external `unpigz` are always hungry.
All the nanosleep are caused by there is not active `G` for sysmon to `retake()`.

Then I will wonder: why this loop device is so slow? Use `losetup` to find `/dev/loop2` on disk, 
you will find it is  `/var/lib/firecracker-containerd/naive/images/1`. This is created by 
`naive.createImage()` with **sparse** data. Actually, I though the "sparse" is the problem,
then I use 

	`ddArgv := []string{ "if=/dev/zero", fmt.Sprintf("of=%s", imagePath), "bs=1k", fmt.Sprintf("count=%d", 1024 * int64(fileSizeMB)) }`
	
to create a filled block device. Then I `mount` the file directly use `mount -o loop`,
because I found it is much faster! But actually, it is the `sync` and `dirsync` make it slow.

	`sudo mount -o loop,sync,dirsync /var/lib/firecracker-containerd/naive/images/1 mnt`
	
And according to the code:

	func (s *Snapshotter) buildMounts(snap storage.Snapshot) ([]mount.Mount, error) {
		// Snapshot changes need to be flushed to disk immediately when unmounting.
		options := []string{"sync", "dirsync"}
		
# FTrace

Linux has a `debugfs`, which provides an interface to debug kernel. Users can use it as `strace` from command line:

	sudo trace-cmd record -e ext4 -p function_graph cp /bin/egrep ./mnt/bin/egrep
	
`egrep` is a script to call `grep` and only 28 bytes long. This outputs 73 MB os stack trace.
