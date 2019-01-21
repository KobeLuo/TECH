---
title: Monitor Filesystem on Mac OS X 未完结
type: categories
comments: true
date: 2019-01-15 18:02:18
categories: Mac Develop
tags: [Monitor FS, 监控文件系统, FSEvent, MACF, fswatch, Dtrace, NSFileCoordinate]
---

### 前言

最近各大网络磁盘厂商都推出了使用才下载的文件同步功能，类似**Dropbox**的[SmartSync](https://www.dropbox.com/smartsync), **oneDrive**的[Store aways](https://www.theverge.com/2018/9/24/17896018/microsoft-onedrive-files-on-demand-macos-mac-feature)等，他们都是实现了远端文件在本地的可视化，但仅仅对部分需要修改或查看的文件提供下载的功能，这样就大大降低了同步过程消耗的时间和流量，仅仅只是下载需要下载的几个文件，这是个非常先进的设计思路，该功能真正体现了云盘的优势和价值。

博主的工作也刚好是云盘相关的业务，因此对于其背后的原理进行了一些探索，得到了一些有用的信息，其中就包括对于文件系统监控的部分知识。

<!-- more -->

### APFS文件系统监控

Mac OS X上关于文件系统监控的方法有很多种，博主只是知道其中的一小部分，列举如下:

#### [FSEventStream](https://developer.apple.com/library/archive/documentation/Darwin/Conceptual/FSEvents_ProgGuide/UsingtheFSEventsFramework/UsingtheFSEventsFramework.html)

FSEventStream是苹果官方提供的一套标准的监控文件事件的API,它通过给定的路径和一些参数来控制监控的数据细节，并传入一个`callback`来接收所有从APFS底层传回的所有事件列表；其关键函数如下：
```objc  注册函数

- (void)start {
    
    @autoreleasepool {
        
        if (!_watchPath) { return; }
        
        self.isExecuting = YES;
        self.isFinished = NO;
        
        CFStringRef watchDir = (__bridge CFStringRef)_watchPath;
        CFArrayRef pathsToWatch = CFArrayCreate(NULL, (const void **)&watchDir, 1, NULL);
        
        FSEventStreamContext *fseventContext = (FSEventStreamContext *)malloc(sizeof(FSEventStreamContext));
        fseventContext->version = 0;
        fseventContext->info = (__bridge void *)(self);
        fseventContext->retain = NULL;
        fseventContext->release = NULL;
        fseventContext->copyDescription = NULL;
        
        FSEventStreamCreateFlags flags = kFSEventStreamCreateFlagNone |
                                         kFSEventStreamCreateFlagWatchRoot |
                                         kFSEventStreamEventFlagItemXattrMod |
                                         kFSEventStreamCreateFlagFileEvents;
        
        FSEventStreamRef stream = FSEventStreamCreate(NULL,
                                                      &watchCallback,
                                                      fseventContext,
                                                      pathsToWatch,
                                                      kFSEventStreamEventIdSinceNow,
                                                      1.0,
                                                      flags);
        
        _loop = CFRunLoopGetCurrent();
        FSEventStreamScheduleWithRunLoop(stream, _loop, kCFRunLoopDefaultMode);
        FSEventStreamStart(stream);
        
        CFRunLoopRun();
        
        FSEventStreamStop(stream);
        FSEventStreamInvalidate(stream);
        FSEventStreamRelease(stream);
        free(fseventContext);
        CFRelease(pathsToWatch);
        stream = NULL;
        fseventContext = NULL;
    }
}

```
里边有很多的参数都可以按照你的需要去设定，具体怎么设定请参考[官方资料](https://developer.apple.com/library/archive/documentation/Darwin/Conceptual/FSEvents_ProgGuide/UsingtheFSEventsFramework/UsingtheFSEventsFramework.html)。

```objc 回调函数

static void watchCallback(ConstFSEventStreamRef streamRef,
                          void *clientCallBackInfo,
                          size_t numEvents,
                          void *eventPaths,
                          const FSEventStreamEventFlags eventFlags[],
                          const FSEventStreamEventId eventIds[]) {
    
    char **paths = eventPaths;
    
    for (int i=0; i < numEvents; i ++) {
        
        int flag = eventFlags[i];
        printf("Change %llu in %s, flags %u\n", eventIds[i], paths[i], flag);
        
        if (flag == kFSEventStreamEventFlagNone) {
            NSLog(@"kFSEventStreamEventFlagNone");
        } else if (flag & kFSEventStreamEventFlagMustScanSubDirs) {
            NSLog(@"kFSEventStreamEventFlagMustScanSubDirs");
        } else if (flag & kFSEventStreamEventFlagUserDropped) {
            NSLog(@"kFSEventStreamEventFlagUserDropped");
        } else if (flag & kFSEventStreamEventFlagKernelDropped) {
            NSLog(@"kFSEventStreamEventFlagKernelDropped");
        } else if (flag & kFSEventStreamEventFlagEventIdsWrapped) {
            NSLog(@"kFSEventStreamEventFlagEventIdsWrapped");
        } else if (flag & kFSEventStreamEventFlagHistoryDone) {
            NSLog(@"kFSEventStreamEventFlagHistoryDone");
        } else if (flag & kFSEventStreamEventFlagRootChanged) {
            NSLog(@"kFSEventStreamEventFlagRootChanged");
        } else if (flag & kFSEventStreamEventFlagMount) {
            NSLog(@"kFSEventStreamEventFlagMount");
        } else if (flag & kFSEventStreamEventFlagUnmount) {
            NSLog(@"kFSEventStreamEventFlagUnmount");
        } else if (flag & kFSEventStreamEventFlagItemCreated) {
            NSLog(@"kFSEventStreamEventFlagItemCreated");
        } else if (flag& kFSEventStreamEventFlagItemRemoved) {
            NSLog(@"kFSEventStreamEventFlagItemRemoved");
        } else if (flag & kFSEventStreamEventFlagItemInodeMetaMod) {
            NSLog(@"kFSEventStreamEventFlagItemInodeMetaMod");
        } else if (flag & kFSEventStreamEventFlagItemRenamed) {
            NSLog(@"kFSEventStreamEventFlagItemRenamed");
        } else if (flag & kFSEventStreamEventFlagItemModified) {
            NSLog(@"kFSEventStreamEventFlagItemModified");
        } else if (flag & kFSEventStreamEventFlagItemFinderInfoMod) {
            NSLog(@"kFSEventStreamEventFlagItemFinderInfoMod");
        } else if (flag & kFSEventStreamEventFlagItemChangeOwner) {
            NSLog(@"kFSEventStreamEventFlagItemChangeOwner");
        } else if (flag & kFSEventStreamEventFlagItemXattrMod) {
            NSLog(@"kFSEventStreamEventFlagItemXattrMod");
        } else if (flag & kFSEventStreamEventFlagItemIsFile) {
            NSLog(@"kFSEventStreamEventFlagItemIsFile");
        } else if (flag & kFSEventStreamEventFlagItemIsDir) {
            NSLog(@"kFSEventStreamEventFlagItemIsDir");
        } else if (flag & kFSEventStreamEventFlagItemIsSymlink) {
            NSLog(@"kFSEventStreamEventFlagItemIsSymlink");
        } else {
            NSLog(@"i don't know!");
        }
    }
}

```
通过回调函数，当文件系统指定的目录及其递归子目录发生变更时，会将对应的事件回调到该函数中，拿到事件后，再继续做后续操作即可。
FSEventStream可以跟踪到事件的发送过程，它得定义是当事件发生后，系统回调给注册者，如果要求是事件发生前先得到信息，根据博主的理解，FSEventStream可能无法满足需求。

#### NSFileCoordinator & NSFilePresenter
[NSFileCoordinator](https://developer.apple.com/documentation/foundation/nsfilecoordinator)和[NSFilePresenter](https://developer.apple.com/documentation/foundation/nsfilepresenter),可以结合起来使用，以达到监控某个路径文件的事件，它是iCloud开发必须掌握的知识，实现的核心方法如下:

{% note info %}
1.创建一个class并遵循<NSFilePresenter>协议，
2.初始化时，将self添加至NSFileCoordinator中，
3.实现NSFilePresenter协议要求的方法，会自动让你填写监控的url和回调函数.
4.打印log监控回调事件.
{% endnote %}
利用NSFilePresenter方式可以监控到文件系统调用`open`和`release`时的回调，值得注意的是该系列函数是在文件执行操作之前回调的，这对于实现类似Dropbox的smartSync功能尤为重要，当文件双击时，首先调用该函数，然后启动下载，下载完成后，再调用默认打开进程去打开文件。

**PS:**文章中提到的``FSEventStream``和``NSFileCoordinate``相关的代码均来自:[Demo地址](https://github.com/KobeLuo/DemoRepo/tree/develop/HybridDemo)， 如果需要可以点击下载代码。

#### fswatch

[fswatch](https://github.com/emcrisostomo/fswatch)是github上的一个开源项目，作者将多种文件监控的方法汇聚到该开源项目中，该项目可以监控来自多个操作系统下的文件事件监控，有兴趣的可以仔细查阅。

fswatch有很多使用方式，其HTML文档地址[在这儿](https://emcrisostomo.github.io/fswatch/doc/),下面是一个经典的使用实例： 

```javascript
fswatch -xr /path/to/observe
```
该实例可以监控到指定目录下的文件的变化情况。

#### Dtrace

这是一个神级工具，该工具位于OSX系统`/usr/bin/dtrace`位置，Instrument绝大部分统计工具其背后统计数据均来自`dtrace`，由于dtrace直接操作系统内核，所以需要的权限非常高，如果需要使用dtrace来实现一些牛逼的功能，需要更改一些电脑的权限，由于其强大的功能，博主并未深究，实在不敢误人子弟，具体如何使用，还请自行查阅。


### 疑问

目前博主在实现类似Dropbox的smartSync功能使用 sparse file + NSFilePresenter相结合的方式，可以实现功能，但由于NSFilePresenter只能监控某一个文件，如果想要获得指定目录及其递归子目录监控，就需要建立大量的FilePresenter，这在性能上是一个瓶颈，也是一种不太好的方式，目前还未找到更好的解决方案！！！
如果有大神有更好的方案，还请赐教一二，博主邮箱地址: kobev5@126.com，也欢迎您给我发邮件探讨关于Mac和iOS上的技术问题。


### 相关连接
 
- [FSEventStream Documentation](https://developer.apple.com/library/archive/documentation/Darwin/Conceptual/FSEvents_ProgGuide/UsingtheFSEventsFramework/UsingtheFSEventsFramework.html)
- [FSEventStream Blog1](https://www.jianshu.com/p/7c37b39b143e)
- [FSEventStream Blog2](https://blog.csdn.net/lovechris00/article/details/78080598)
- [NSCoordinator](https://developer.apple.com/documentation/foundation/nsfilecoordinator)
- [NSFilePresenter](https://developer.apple.com/documentation/foundation/nsfilepresenter)
- [fswatch](https://github.com/emcrisostomo/fswatch)
- [DTrace](http://dtrace.org/blogs/brendan/2011/10/10/top-10-dtrace-scripts-for-mac-os-x/)