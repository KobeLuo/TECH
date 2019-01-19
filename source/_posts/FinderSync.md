---
title: FinderSync插件的使用及调试
type: categories
comments: true
date: 2018-01-15 18:01:23
categories: Mac Develop
tags: [FinderSync, Finder插件, 右键菜单, 文件图标]
---

### [FinderSync](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Finder.html) 简要描述

[FinderSync](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Finder.html)是苹果官方提供的一个用来扩展Finder进程的一个插件，它通过监控Finder进程的一个URL组来实现对指定路径下的文件及文件夹的指定事件进行回调，一般它用于文件同步产品或者Finder相关的开发产品，它主要的功能有以下几点:

- **在Finder上创建一个自定义的右键菜单按钮以及点击后的事件回调**
<!--more-->
- **在Finder上创建toolbar快捷按钮及事件回调**
- **自定义sidebarIcon(侧边栏图标)**
- **控制的目录及其递归子目录下的文件和文件夹的图标变化**


关于如何是用FinderSync插件博主就不介绍了，很简单，[苹果官方文档](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Finder.html).

这篇文章的主要目的是介绍如何手动调试`FinderSync`。


### FinderSync调试

在早期时间，`FinderSync`可以通过挂在到Finder进程上直接启动调试，不知道从什么时候开始，直接调试`FinderSync`时，它会一直处于**Waiting to Attch**这样一直状态，该进程一直停留在这个状态上，调试`FinderSync`变成了一件非常恶心的事情，它是独立于主进程(main application)之外的另一个进程，因此你无法直接在主进程中进行断点调试，如果你直接使用NSLog来查看日志也是行不通的，博主这里提供两种调试方式:

#### 记录日志到磁盘

通过`writeToFile`方法将log日志记录到本地指定文件下，通过文件的内容变更来调试FinderSync,这种方式可以通过查看本地日志来完成`FinderSync`的调试，但效率非常低。

#### 创建额外的FinderSync

通过调试发现，如果你的产品项目有多个Target,并且有多个FinderSync插件的时候，通过启动其它的插件可以把你想调试的插件一并启动起来，设置断点后可以直接进行调试，博主并不知道这是为什么，但它的确是可行并有效地，具体处理方法如下:

1. 假设有一个工程叫`SmartSync`,`SmartSync`中的主进程叫`remoteSync`,它用于做远程文件系统同步相关工作。
2. 你可能需要FinderSync插件来完成一些特殊的功能，此时你可以直接从target中选中FinderSync插件，并命名为**FinderSync_main**，并将它作为`remoteSync`的插件。
3. 为了调试方便，现在你再创建一个*target*叫做`remoteSync_help`,然后再从target中选取一个Findersync插件，命名为**FinderSync_helper**,将它作为`remoteSync_help`的插件。
4. 正常启动你的主进程`remoteSync`，`FinderSync_main`会跟随主进程自动启动起来，此时你可以在系统进程监视窗口`ActivityMonitor`中直接把`FinderSync_main`Kill掉，或者干脆什么也不做。
5. 选中target`FinderSync_helper`并运行他，`Xcode`会让你选择一个app来加载，选择Finder,然后`FinderSync_helper`会加载起来，并主动将`FinderSync_main`也附带加载起来。
6. 此时在`FinderSync_main`的代码中打断点，就可以直接调试了。


