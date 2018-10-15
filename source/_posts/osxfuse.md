---
title: mac上建立基于osx fuse的虚拟磁盘
date: 2017-07-24 20:25:04
type: "categories"
categories: Objective-C
tags: [FUSE,Mount Disk,LookbackFS]
---
{% cq %} 
苹果文件系统[AFPS](https://www.google.co.kr/search?q=APFS&oq=APFS&aqs=chrome..69i57j0l5.5335j0j7&sourceid=chrome&ie=UTF-8)允许用户挂载自己的磁盘(Mount disk)，类似[PCloud](https://www.pcloud.com/zh/)；也允许用户通过底层API来监控某个文件夹的变化来做同步，类似[DropBox](https://www.dropbox.com/)，最终目的都是为了实现本地文件与服务端同步来方便人们的工作和生活，博主对于两种方式来同步文件都有一定涉猎，国内外目前针对Mount盘的文献和资料相对较少，博主在工作过程中遇到过很多的坑，共享出来，希望能帮助到有缘人。
{% endcq %}

<!--more-->

### [OSX FUSE](https://osxfuse.github.io/)
---

#### osxfuse介绍
关于osx fuse，官方的介绍已经非常详尽了，它主要针对Mac OS文件系统相关的一些操作提供底层的SDK帮助,其主要功能如下:
{% note info %}
1. AccessibilityFS 
2. LoopbackFS   
3. SpotlightFS    
4. SSHfs
5. other functions
{% endnote %}
- **LoopbackFS** 将Finder中某个文件夹作为一个独立的文件系统挂载起来;
- **SpotlightFS**   OS特有的文件系统，连接spotlight使用的，当使用spotlight搜索时，会存储搜索结果;
- **SSHfs**  基于SSH的文件系统，用于挂载远程的文件系统。
本篇文章将主要介绍使用OSX FUSE来搭建自己的mount盘.

#### osxfuse安装
下载[osx fuse.dmg](https://github.com/osxfuse/osxfuse/releases)，安装后`system preferences`底部会多一个FUSE item，![system preference screenshot](fusePanel.png)
下载[osxfuse.framwork](https://github.com/osxfuse/framework)，使用xcode编译后导入到自己自己工程中。

#### osxfuse结构介绍
这里以[LookbackFS](https://github.com/osxfuse/filesystems)的swift版本为例介绍fuse的基本概念及用法.
{% codeblock 需要初始化的参数 lang:Swift  %}
private var rootPath: String!
private lazy var loopFileSystem: LoopbackFS = {
    return LoopbackFS(rootPath: self.rootPath)
}()

private lazy var userFileSystem: GMUserFileSystem = {
    return GMUserFileSystem(delegate: self.loopFileSystem, isThreadSafe: false)
}()
{% endcodeblock %}
- rootPath 由于LookbackFS是义某个文件夹作为mount的对象，因此rootPath就是本地某个文件夹地址；
- loopFileSystem该参数作为osx回调的代理，用来接收所有从底层过来的消息；
- userFileSystem该参数主要作为启动mount的载体，加载mount需要的各项参数。

#### Mount挂载

{% codeblock Mount lang:Swift  %}

self.rootPath = rootPath

addNotifications()

var options: [String] = ["native_xattr", "volname=LoopbackFS"]
if let volumeIconPath = Bundle.main.path(forResource: "LoopbackFS",
ofType: "icns") {

    options.insert("volicon=\(volumeIconPath)", at: 0)
}
userFileSystem.mount(atPath: "/Volumes/loop", withOptions: options)
{% endcodeblock %}
该片段代码展示了mount 过程的细节，其中[options](https://github.com/osxfuse/osxfuse/wiki/Mount-options)是OSX FUSE指定的某些特定参数，用以实现不同的mount盘功能。
而`/Volumes/loop`则是在macbook上挂载的mount盘的地址,如下图:

![mount disk info](mountinfo.png)
图中可以看出，mount盘在Macintosh中的地址是`/Volumes/loop`,而显示的名字是`LoopbackFS`。
![mount disk info](path.png)
接下来是注册mount结果的通知
{% codeblock Notification lang:Swift  %}

func addNotifications() {

    NotificationCenter.default.addObserver(forName: NSNotification.Name(kGMUserFileSystemDidMount), object: nil, queue: nil) { notification in
        Log.record(info: "Got didMount notification.")
        //do something.
    }

    NotificationCenter.default.addObserver(forName: NSNotification.Name(kGMUserFileSystemMountFailed), object: nil, queue: .main) { notification in
        Log.record(info: "Got mountFailed notification.")
    }

    NotificationCenter.default.addObserver(forName: NSNotification.Name(kGMUserFileSystemDidUnmount), object: nil, queue: nil) { notification in
        Log.record(info: "Got didUnmount notification.")
        NSApplication.shared().terminate(nil)
    }
}
{% endcodeblock %}
当mount盘发生状态变更时会调用到该函数中，至此，mount盘就已经挂载到了APFS上。

### Event Stream
--- 
#### mount盘事件原理
前文提到注册mount盘的过程实例化了一个loopFileSystem，以下简称loopInvoke，它主要用来接收从底层过来的所有的事件信息，loopInvoke实现了所有的GMUserFileSystem的代理方法。前文Mount的过程其实质是osxfuse向APFS注册了事件的回调反馈，用户在Mount盘中的任何行为，都将以flag的形式反馈给osx fuse，osx fuse通过解析这些flag并转化成上层可以读懂的事件反馈到loopInvoke实例，如果需要返回值，则将loopInvoke处理后的返回值返回给APFS。
```flow
st=>start: Start
e=>end: End
evt=>operation: User Operation
op1=>operation: APFS 
op2=>operation: Fuse parse and generate
op3=>operation: loopInvoke handle event
cond=>condition: has return value?
st->evt->op1->op2->op3(right)->cond
cond(yes,top)->op1
cond(no,bottom)->e
```

#### loopInvoke事件详解
##### 回调函数列表:
先看一下loopInvoke回调事件函数列表如下:
```swift 函数列表
//create
override func createDirectory(atPath path: String!, attributes: [AnyHashable : Any]! = [:]) throws
override func createFile(atPath path: String!, attributes: [AnyHashable : Any]! = [:], flags: Int32, userData: AutoreleasingUnsafeMutablePointer<AnyObject?>!) throws
//remove
override func removeDirectory(atPath path: String!) throws
override func removeItem(atPath path: String!) throws
//other important
override func moveItem(atPath source: String!, toPath destination: String!) throws
override func openFile(atPath path: String!, mode: Int32, userData: AutoreleasingUnsafeMutablePointer<AnyObject?>!) throws
override func releaseFile(atPath path: String!, userData: Any!)
override func readFile(atPath path: String!, userData: Any!, buffer: UnsafeMutablePointer<Int8>!, size: Int, offset: off_t, error: NSErrorPointer) -> Int32
override func writeFile(atPath path: String!, userData: Any!, buffer: UnsafePointer<Int8>!, size: Int, offset: off_t, error: NSErrorPointer) -> Int32
public override func exchangeDataOfItem(atPath path1: String!, withItemAtPath path2: String!) throws
override func contentsOfDirectory(atPath path: String!) throws -> [Any]
//attributes
override func finderAttributes(atPath path: String!) throws -> [AnyHashable : Any]
override func resourceAttributes(atPath path: String!) throws -> [AnyHashable : Any]
override func attributesOfItem(atPath path: String!, userData: Any!) throws -> [AnyHashable : Any]
override func attributesOfFileSystem(forPath path: String!) throws -> [AnyHashable : Any]
override func setAttributes(_ attributes: [AnyHashable : Any]!, ofItemAtPath path: String!, userData: Any!) throws
public override func extendedAttributesOfItem(atPath path: Any!) throws -> [Any]
public override func value(ofExtendedAttribute name: String!, ofItemAtPath path: String!, position: off_t) throws -> Data
public override func setExtendedAttribute(_ name: String!, ofItemAtPath path: String!, value: Data!, position: off_t, options: Int32) throws
public override func removeExtendedAttribute(_ name: String!, ofItemAtPath path: String!) throws
//link 
override func linkItem(atPath path: String!, toPath otherPath: String!) throws
//symbolic link
override func createSymbolicLink(atPath path: String!, withDestinationPath otherPath: String!) throws
override func destinationOfSymbolicLink(atPath path: String!) throws -> String
//pre alloc
override func preallocateFile(atPath path: String!, userData: Any!, options: Int32, offset: off_t, length: off_t) throws
```
哇！！！乱七八糟一大堆函数回调，实际上仔细归类后发现，基本上涵盖了文件操作的所有细节。

{% note danger %}
**这些细节全部由你来掌控！**
- 当用户创建一个文件A时，APFS会通过OSX FUSE传递到loopInvoke，告诉你现在收到一个信号是创建了一个A文件，问你怎么办？
- 当APFS需要读取A文件的属性时发出信号向你询问A文件的属性应该是怎样的？
- 当A文件被更名成B文件时，发出信号告诉你有这个事情，至于是否需要更名成B文件或者抛错，由你来决定！
{% endnote %}


##### 事件详解
以create函数为例来分析一下事件的过程。
```swift create file event
override func createFile(atPath path: String!, attributes: [AnyHashable : Any]! = [:], flags: Int32, userData: AutoreleasingUnsafeMutablePointer<AnyObject?>!) throws {

    guard let mode = attributes[FileAttributeKey.posixPermissions] as? mode_t else {
        throw NSError(posixErrorCode: EPERM)
    }

    let originalPath = rootPath.appending(path)

    let fileDescriptor = open((originalPath as NSString).utf8String!, flags, mode)

    if fileDescriptor < 0 {
        throw NSError(posixErrorCode: errno)
    }

    userData.pointee = NSNumber(value: fileDescriptor)
}
```
**参数解析**
- mode 是[open2](http://www.man7.org/linux/man-pages/man2/open.2.html)函数的参数，该参数必须指定为`O_CREAT`或者`O_TMPFILE`flag，如果不是这两个参数，那么该参数将被忽略。
> 以下是官方解释
The mode argument specifies the file mode bits be applied when a new file is created.  
This argument must be supplied when O_CREAT or O_TMPFILE is specified in flags; 
if neither O_CREAT nor O_TMPFILE is specified, then mode is ignored.
- originalPath 是指实际文件系统中文件的路劲
- flags 用于指定文件创建时的打开方式的集合，官方的解释如下:
> 以下是官方解释
The argument flags must include one of the following access modes: O_RDONLY, O_WRONLY, or O_RDWR.  
These request opening the file read-only, write-only, or read/write, respectively.
In addition, zero or more file creation flags and file status flags can be bitwise-or'd in flags.  
The file creation flags are O_CLOEXEC, O_CREAT, O_DIRECTORY, O_EXCL, O_NOCTTY, O_NOFOLLOW, O_TMPFILE, and O_TRUNC.
- fileDescription 是指文件句柄，该文件句柄用于文件操作过程中的唯一标志符。
- userData是一个指针，用来存储文件操作过程中用户定义的数据，该字段在实际项目中作用很大。
{% note danger %}
**总结:**

通过解析create函数，可以看出，APFS将所有的事件都会发送到loopInvoke，至于怎么处理事件，由开发者自己来决定！
也正因为如此，Mount开发需要谨慎对待，处理不善，可能就无法正常运转Mount盘。
{% endnote %}



