---
title: Monitor Filesystem on Mac OS X 未完结
type: categories
comments: true
date: 2019-01-15 18:02:18
categories: Mac Develop
tags: [Monitor FS, 监控文件系统, FSEvent, MACF, fswatch, Dtrace, NSFileCoordinate]
---

### 前言

最近各大网络磁盘厂商都推出了使用才下载的文件同步功能，类似[Dropbox](dropbox.org)的`SmartSync`, [oneDrive](https://onedrive.live.com/)的`Store aways`等，他们都是实现了远端文件在本地的可视化，但仅仅对部分需要修改或查看的文件提供下载的功能，这样就大大降低了同步过程消耗的时间和流量，仅仅只是下载需要下载的几个文件，这是个非常屌的设计思路，该功能真正体现了云盘的优势和价值。

博主的工作也刚好是云盘相关的业务，因此对于其背后的原理进行了一些探索，得到了一些有用的信息，其中就包括对于文件系统监控的部分知识。

<!-- more -->

### APFS文件系统监控