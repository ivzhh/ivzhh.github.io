---
layout: post
title:  "Four Months of ZFS/BTRFS/LVM"
comments: true
---

# Background

- Q: what platform are you referring to?
- A: Both Pi 4 4G (ARM64) and Intel i7-8xxx laptop.

# General Discussion

## ZFS

- Q: Did you experience data loss?
- A: Yes. I use an old USB (250G) HDD attached on Pi 4. Disk dies after four months.
The main problem is too old and low quality. Another problem is the driver (maybe).
A good discussion is recorded in [reddit](https://www.reddit.com/r/zfs/comments/im70rm/share_some_sad_story_on_zfs_raspberry_pi_4/).

- Q: Where is ZFS `zfs` folder in recursive snapshot?
- A: After performing recursive snapshot on dataset, the `.zfs` folder only exists on
the root.

- Q: How to send all children datasets recursively?
- A: On sending side, use `zfs send -R`; on receiving side, use `zfs recv -Fdu`. 
Refer to [this post](https://blogs.ubc.ca/edmundseow/tips-and-tricks/).

- Q: How to speed up send/recv?
- A: Use [raw transmission](https://everycity.co.uk/alasdair/2010/07/using-mbuffer-to-speed-up-slow-zfs-send-zfs-receive/) instead of SSH channel. 
On sending side, use `mbuffer -s 128k -m 1G -O 10.0.0.1:9090`; 
on receiving side, use `mbuffer -s 128k -m 1G -I 9090`.

## BTRFS

# KVM

## ZFS

## BTRFS
