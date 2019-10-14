---
title: 开发的一些站点记录
type: categories
comments: true
date: 2016-11-16 14:22:21
categories: Tools
tags:
---

### About Debug：

[理解和分析崩溃报告](https://developer.apple.com/library/archive/technotes/tn2151/_index.html#//apple_ref/doc/uid/DTS40008184-CH1-SYMBOLICATIONTROUBLESHOOTING)
[Objective-C 中提高log的方法](https://developer.apple.com/library/archive/qa/qa1669/_index.html)



### WWDC

[2018](https://developer.apple.com/videos/wwdc2018/)



### About filesystem 

[Mac OS X Hidden Files & Directories](http://www.westwind.com/reference/OS-X/invisibles.html)


<!-- [![DSC-5880.jpg](https://i.postimg.cc/59QjfzcQ/DSC-5880.jpg)](https://i.postimg.cc/m489N38j/DSC-5880.jpg)
![123](https://i.postimg.cc/m489N38j/DSC-5880.jpg) -->


### Inter Process Communication
[IPC For Mac](http://mirror.informatimago.com/next/developer.apple.com/documentation/MacOSX/Conceptual/SystemOverview/InverEnvironissues/chapter_52_section_4.html)
[XPC原文](https://www.objc.io/issues/14-mac/xpc/)
[XPC译文](https://objccn.io/issue-14-4/)


### Access control lists
[ACLs](http://ahaack.net/technology/OS-X-Access-Control-Lists-ACL.html)-


### File Monitor
[FSEventStreamDemo](https://github.com/ywwzwb/FSEventStreamDemo)
[fswatch](https://github.com/emcrisostomo/fswatch)

### Deamon process

Launch Daemons
Daemons are managed by launchd on behalf of the OS in the system context, which means they are unaware of the users logged on to the system. A daemon cannot initiate contact with a user process directly; it can only respond to requests made by user processes. Because they have no knowledge of users, daemons also have no access to the window server, and thus no ability to post a visual interface or launch a GUI application. Daemons are strictly background processes that respond to low-level requests.

Most daemons run in the system context of the system—that is, they run at the lowest level of the system and make their services available to all user sessions. Daemons at this level continue running even when no users are logged into the system, so the daemon program should have no direct knowledge of users. Instead, the daemon must wait for a user program to contact it and make a request. As part of that request, the user program usually tells the daemon how to return any results.

For information about how to create a launch daemon, see Creating Launch Daemons and Agents.
系统级，与用户无关并可适用于所有用户的进程可以使用守护进程，但守护进程无法直接发起与用户级进程的通信，只能被动等待用户级进程主动联系守护进程。

[System Startup Programming](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/Introduction.html)
[Deamon And Agent](https://developer.apple.com/library/archive/technotes/tn2083/_index.html)
[Designing deamon and services](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/DesigningDaemons.html#//apple_ref/doc/uid/10000172i-SW4-BBCBHBFB)
[crate Deamon or agent](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html#//apple_ref/doc/uid/10000172i-SW7-BCIEDDBJ)
[Launchd.plist manual page](https://www.manpagez.com/man/5/launchd.plist/)
[The flow of create launch agent](https://www.codepool.biz/how-to-create-a-background-service-on-mac-os-x.html)

启用和进制服务：
```
启用服务
launchctl load /path/to/plist
禁用服务
launchctl unload /path/to/plist

```

### run as root application
[Authorization service](https://developer.apple.com/library/archive/documentation/Security/Conceptual/authorization_concepts/03authtasks/authtasks.html#//apple_ref/doc/uid/TP30000995-CH206-TPXREF12)
