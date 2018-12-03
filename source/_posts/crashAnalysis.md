---
title: iOS/Mac OS下的 Crash 崩溃分析
type: categories
comments: true
date: 2017-11-16 13:35:48
categories: Mac Develop
tags: 
- 崩溃日志
- 崩溃解析
- crash analysis
- .dSYM .crash
---

就普通的开发而言，普通需求的实现，对于大多数有经验的开发者只是时间问题，其实并没有太大的难度，需求的实现过程则相对轻松；

比较恶心的是发布产品后，遇到的各式奇葩的crash，如果你早有准备，在发布的时候打包了符号文件，那么恭喜你，你还可以通过符号文件来查找崩溃代码，否则，可能就是让bug出现者不停的复现crash，费事费力，可能最终还找不到问题。

符号文件可以通过一定规则将内存地址转换为可读的函数名和一些代码的行号，当你通过Xcode窗口产生的crash时，通常在console中看到的结果是已经被符号化的结果。

一般的崩溃日志都会产生一个线程回溯列表，让你去回溯到指定的crash函数，但是内存警告不会产生线程回溯，官方的解释是低内存发生时不需要线程回溯信息，当发生内存警告时，你必须要重视内存的使用模式并在内存警告发生时的回调函数处理相关的内存泄露。

本文大多数内容来源于Apple的官方文档，[地址在这](https://developer.apple.com/library/archive/technotes/tn2151/_index.html)

这篇博文意在如何收集crash，如何分析crash.
<!--more-->
### crash日志的收集

#### 常规发布和崩溃信息收集流程
先看苹果官方的一张流程图如下：

![crash connect](https://developer.apple.com/library/archive/technotes/tn2151/Art/tn2151_crash_flow.png)

1.编译器将源码转化成机器码，并生成调试符号文件，用于将机器码回溯成源代码的行号和函数名，关于dsYM的设置可以在`BuildSettings`搜索*DEBUG_INFORMATION_FORMAT*设置，这些调试符号存储在二进制文件中或者.dsYM文件中，debug包的应用存储编译后的二进制文件中，而release包的的符号文件则伴随在*.dsYM*文件中，以便节省包的大小。

调试符号文件和产品二进制包被捆包在一个基于每次编译的一个UUID, 每次编译都会产生一个新的UUID,即使没有任何内容更改。

2.一旦你使用Archive了一个发布包，Xcode会生成一个带有.dsYM的二进制包到Xcode的oranizer下的Archived组。
![archived](orgnizerArchived.png)

3.当你上传准备好的二进制包到iTunesConnect时，有一个可选项是让你选择二进制包是否包含.dSYM文件*Include app symbols for your application…*,为了后续分析问题方便，建议勾选。

4.产品发布后，关于你的产品的任何崩溃都将在用户的手机中创建并存储崩溃信息。

5.用户可以从设备中通过[调试发布的产品](https://developer.apple.com/library/archive/qa/qa1747/_index.html)中直接取到crash报告。如果你的包是“AdHoc”或"Enterprise"企业版发布，那么这种方式将是苹果提供的唯一一种读取崩溃报告的方式。

6.通过Xcode将你取到的.crash文件通过.dSYM文件反解析成崩溃的响应行号和函数名。

7.如果发送崩溃的用户愿意分享崩溃报告的数据，该crash文件将上传至App Store，你可以直接从App Store下载响应的崩溃文件。

8.Apple Store符号化崩溃报告，并将类似的崩溃报告组合在一起，形成一个相似的崩溃报告，这被称为崩溃点。

9.crash崩溃报告也可以在“Organizer的Crash组”中看到。 

#### .dsYM文件的获取方式

- 通过“Organizer的Archived”找到你发布的相应包，然后右键“ShowInFinder”去找
![finder](finderShowPackage.png)
![dSYM](dsYM.png)

- 通过iTunes Connect查找。
具体方法是登录iTunesConnect,点击某个APP详情页，从所有的编译版本中找到需要的版本，然后点击下载相应的dSYM文件。

#### 识别崩溃报告是否被符号化
一个崩溃报告的符号化状态有三种:“未符号化”、"部分符号化"和"完全符号化"，下面是官方给的符号化示意图:
![](https://developer.apple.com/library/archive/technotes/tn2151/Art/tn2151_symbolication_levels.png)

#### 符号化的方式

##### 使用Xcode来符号化崩溃报告

对于可直接获取设备的崩溃可以采用以下方式
> 1.Connect an iOS device to your Mac
> 2.Choose "Devices" from the "Window" menu
> 3.Under the "DEVICES" section in the left column, choose a device
> 4.Click the "View Device Logs" button under the "Device Information" section on the right hand panel
> 5.Drag your crash report onto the left column of the presented panel
> 6.Xcode will automatically symbolicate the crash report and display the results

##### 使用atos来符号化崩溃报告
atos命令可以将地址转化成可读的行号和函数名，它可以符号化线程回溯中的一个独立的地址，换言之，他可以做部分符号化，
其命令如下:
![](https://developer.apple.com/library/archive/technotes/tn2151/Art/tn2151_atos_info.png)
```C
atos -arch <Binary Architecture> -o <Path to dSYM file>/Contents/Resources/DWARF/<binary image name> -l <load address> <address to symbolicate>
```
其中 Binary Architecture指的是崩溃设备的架构，在.crash文件顶部的Code Type,mac上一般是x86-64的架构。

简单的使用方法总结如下:
```
1.找到crash文件相应版本号下的dSYM文件
2.下载相应.crash文件，并打开。
3.找到.crash文件顶部信息中的CodeType并记录,它包含ARM-64, ARM, x86-64, or x86.
4.在.crash文件中搜索Binary Images:,并记下你的包对应的 loadAddress
loadAddress也可以通过计算得到，等于（symbolicateAddress转10进制 - 偏移量）再转16进制，
loadAddress的后三位通常都是000，如果不是，则可能计算有误。

5.终端cd到 dSYM文件package contents下的DWARF目录
6.执行: atos -arch x86_64 -o appNameInDWARF -l loadAddress symbolicateAdress
```

### 分析崩溃报告

这部分内容讨论当你获取到`.crash`文件时，如何分析崩溃信息。

#### Header信息
每一个`.crash`文件的第一部分内容都是一个格式相同的header信息。
```
Incident Identifier: B6FD1E8E-B39F-430B-ADDE-FC3A45ED368C
CrashReporter Key: f04e68ec62d3c66057628c9ba9839e30d55937dc
Hardware Model: iPad6,8
Process: TheElements [303]
Path: /private/var/containers/Bundle/Application/888C1FA2-3666-4AE2-9E8E-62E2F787DEC1/TheElements.app/TheElements
Identifier: com.example.apple-samplecode.TheElements
Version: 1.12
Code Type: ARM-64 (Native)
Role: Foreground
Parent Process: launchd [1]
Coalition: com.example.apple-samplecode.TheElements [402]
 
Date/Time: 2016-08-22 10:43:07.5806 -0700
Launch Time: 2016-08-22 10:43:01.0293 -0700
OS Version: iPhone OS 10.0 (14A5345a)
Report Version: 104
```
相关字段解释如下：
- Incident Identifier: 每一份`.crash`文件的唯一标志，不同的崩溃文件的唯一标志不重复
- CrashReporter Key: 匿名的设备标志，只要来自该设备的崩溃信息的crashReporterKey都是一样的
- Process: 崩溃进程的可执行名称，匹配项目`info.plist`文件中的`CFBundleExecutable` key
- Version: 崩溃进程的版本号，匹配项目`info.plist`文件中的`CFBundleVersion`和`CFBundleVersionString` key
- Code Type: 崩溃进程所在机器的架构模式，目前的架构模式有`ARM-64, ARM, x86-64, x86`
- OS Version: OS系统版本号
- Role: 在进程crash时分配给进程的[task role](http://opensource.apple.com/source/xnu/xnu-3248.60.10/osfmk/mach/task_policy.h)

通过以上Header信息的分析，可以获取到崩溃报告的环境内容，通过符号化可以将符号文件符号到的代码行，这样基本上可以获取到崩溃的大致情况。

#### Mach 异常信息解析

##### Mach信息解读

这里所说的Mach 异常信息解析跟Objective-C/C++的异常信息不同，它表示在内核态的崩溃信息，当然并不是所有的崩溃都来自内核态，但当进程崩溃时，内核态会有一个信息表示在`.crash`文件中，以供参考

比如以下崩溃信息来自一段未被捕获的OC代码崩溃时的内核态信息
```
Exception Type: EXC_CRASH (SIGABRT)
Exception Codes: 0x0000000000000000, 0x0000000000000000
Exception Note: EXC_CORPSE_NOTIFY
Triggered by Thread: 0

```
而以下是来自一个NULL指针的取消引用引发的崩溃是内核态信息
```
Exception Type: EXC_BAD_ACCESS (SIGSEGV)
Exception Subtype: KERN_INVALID_ADDRESS at 0x0000000000000000
Termination Signal: Segmentation fault: 11
Termination Reason: Namespace SIGNAL, Code 0xb
Terminating Process: exc handler [0]
Triggered by Thread: 0
```
相关字段解释如下:
- Exception Code: 当进程崩溃时，崩溃信息被编码成一个或多个64位的十六进制号码，一般情况下这个字段不会展示因为都以更友好的方式展示到了其它字段
- Exception Subtype: 对`Exception Code`的可视化解释
- Exception Message: 对`Exception Code`的附加解释和说明
- Exception Note: 对崩溃信息的另一种附加说明，如果该字段包括`SIMULATED`则说明进程并不是真正的产生了崩溃，而是因为系统要求而被Kill掉，典型的例子:[看门狗](https://en.wikipedia.org/wiki/Watchdog_timer)
- Terminal Reason: 进程的内部和外部关键组件在进程发送错误时将进程结束时的原因
- Triggered by Thread: 进程崩溃的线程号

### 常规异常类型解读

##### 内存访问错误 (EXC_BAD_ACCESS、 SIGSEGV、SIGBUS)
进程尝试访问一个无效的内存地址，或者尝试访问没有权限的访问的内存地址都将引发内存访问错误。当内存访问错误发生时，`.crash`文件的`Exception Subtype1`会包含一个`kern_return_t`的描述错误和读取时的错误内存地址。

以下是调试内存访问错误的提示:
- 如果`objc_msgSend`或`objc_release`接近线程回溯的顶部，那么该进程可能尝试访问一个已经被销毁的内存地址。使用Instrument的`Zombies`对于定位crash可能是更好的方式
- 如果`gpus_ReturnNotPermittedKillClient`接近线程回溯的顶部，那么该进程可能是在后台尝试是用OpenGL或Metal来处理渲染工作，该问题的讨论地址[在这](https://developer.apple.com/library/archive/qa/qa1766/_index.html)
- 在项目的Secheme中开启`Address Sanitizer`，当发送内存崩溃时，Xcode会自动提醒

##### 异常退出 (EXC_CRASH、 SIGABRT)
进程异常退出最常见的原因就是一个未被捕获的Objective-C/C++的错误和调用了`abort()`函数
App的扩展程序也可能产生类似的崩溃信息，如果太多次的被初始化。如果一个扩展程序在launch过程中Hang了，Exception Subtype将报`LAUNCH_HANG`，因为扩展程序并没有`main（）`函数，扩展程序或其独立库的时间花销都在静态构造器和`+load()`函数中

##### 跟踪陷阱 (EXC_BREAKPOINT、 SIGTRAP)
这种异常为附加调试者一个在进程执行体中的某个指定点中断进程的机会，你可以在代码中的某个位置添加函数`__builtin_trap()`来触发该异常，如果没有调试者被附加，那么进程将结束并生成一个崩溃报告

Apple底层的一些库（如libdispatch）也会使用这种方式在发生致命错误时来捕获进程，附加信息将会在console中体现，也可以[在这查询](https://developer.apple.com/library/archive/technotes/tn2151/_index.html#//apple_ref/doc/uid/DTS40008184-CH1-APPINFO)

Swift也经常用到trap机制来引发异常，比如在运行时状态下:
- 一个不可选的value被置为nil时
- 类型强转失败时

##### 非法指令 (EXC_BAD_INSTRUCTION、 SIGILL)
当进程尝试执行一个非法的或未经定义的指令时，进程可能会尝试通过一个错误的函数指针跳转到一个错误的地址，从而会引发该错误。
在Inter处理器上面，`ud2`操作码会引发一个`EXC_BAD_INSTRUCTION`异常，但通常也是使用这个trap来达到调试的目的。而Inter处理器上的Swift代码在运行时遇到意外情况将引发该错误

##### 退出Quit （SIGQUIT）

进程结束于另一个有权管理其生命周期的进程，因此`SIGOUT`并不意味这该进程发生了崩溃，但是它也可能以一种可以检测的方式发生异常。

在iOS系统中，如果键盘扩展加载时间过长，主机应用程序将退出键盘扩展。崩溃报告中显示的线程回溯不太可能指向具体的响应代码。而最有可能的情况是，扩展的启动路径上的其他一些代码花了很长时间才完成，但是在时间限制之前已经完成了，并且在退出扩展时将执行代码显示在线程回溯上。您应该对扩展进行概要分析，以便更好地理解启动期间的大部分工作发生在哪里，并将该工作转移到后台线程，或者将其延迟到稍后(在加载扩展之后)。

##### 被杀死 Killed (SIGKILL)
说明该进程被系统杀死，并且在崩溃信息的Header的`Exception Reason`字段中会包含一个命名空间，后面跟随一个代码

{% note info %}
The following codes are specific to watchOS:

- The termination code 0xc51bad01 indicates that a watch app was terminated because it used too much CPU time while performing a background task. To address this issue, optimize the code performing the background task to be more CPU efficient, or decrease the amount of work that the app performs while running in the background.
- The termination code 0xc51bad02 indicates that a watch app was terminated because it failed to complete a background task within the allocated time. To address this issue, decrease the amount of work that the app performs while running in the background.
- The termination code 0xc51bad03 indicates that a watch app failed to complete a background task within the allocated time, and the system was sufficiently busy overall that the app may not have received much CPU time with which to perform the background task. Although an app may be able to avoid the issue by reducing the amount of work it performs in the background task, 0xc51bad03 does not indicate that the app did anything wrong. More likely, the app wasn’t able to complete its work because of overall system load.

{% endnote %}

##### 违反受保护资源 （EXC_GUARD）
当访问系统被保留或受保护的资源时，会引发一个`EXC_GUARD`错误，这些被保留的资源只允许在系统级的私有API才能访问。
在较新版本的iOS系统中，当违反了被保留的资源时，会在`Exception Subtype`和`Exception Message`字段中以更友好的方式提示给开发者，但是在Mac OS和早起的iOS系统中，该错误信息只会在`Exception Code`中体现，具体分解如下:
{% note info %}
as a bitfield which breaks down as follows:

[63:61] - Guard Type: The type of the guarded resource. A value of 0x2 indicates the resource is a file descriptor.
[60:32] - Flavor: The conditions under which the violation was triggered.
- If the first (1 << 0) bit is set, the process attempted to invoke close() on a guarded file descriptor.
- If the second (1 << 1) bit is set, the process attempted to invoke dup(), dup2(), or fcntl() with the F_DUPFD or F_DUPFD_CLOEXEC commands on a guarded file descriptor.
- If the third (1 << 2) bit is set, the process attempted to send a guarded file descriptor via a socket.
- If the fifth (1 << 4) bit is set, the process attempted to write to a guarded file descriptor.

[31:0] - File Descriptor: The guarded file descriptor that the process attempted to modify.

{% endnote %}

##### 超出资源限制 Resource Limit （EXC_RESOURCE）

该进程超出了资源消耗限制。这是来自操作系统的一个通知，进程使用了太多的资源。在`Exception Subtype`字段中列出了准确的信息。如果`Exception Note`字段包含`NON FATAL`,`CONDITION`，那么即使生成了崩溃报告，进程也不会被终止。

- 如果`Exception Subtype`为`MEMORY`代表该进程已经超越了系统准予的内存限制，这可能是终止超量内存使用的前兆。
- 如果`Exception Subtype`为`WAKEUPS`代表该进程中的线程在每秒中被过于频繁的唤醒，这将会强制CPU频繁唤醒，进而影响到电池的使用寿命。

通常情况下，发生这种情况的原因是线程与线程之间的通信(比如使用`performSelector:onThread:`或`dispatch_async`)，它们的通信频率远远超出了它们应该有的通信频率，当发生类似情况时，有很多个后台线程都有相同的线程回溯，都指向了调用源。

##### 其他异常类型
有一些崩溃报告中，会出现一个未命名的`Exception Type`,这类型异常会以一个十六进制的值表示，对于类似情况，直接可以从`Exception Code`中读取该值
- 0xbaaaaaad 该code不是崩溃信息，它表示该log为整个系统的堆栈快照
- 0xbad22222 表示该进程是一个VoIP进程，因为过于频繁的resume而发生异常崩溃
- 0x8badf00d 表示iOS进程因为看门狗超时而崩溃，可能是应用在launch、terminate或响应系统事件时消耗了太多时间而发生的超时，最常见的错误就是在主线程去同步做网络任务而导致的崩溃。
- 0xc00010ff indicates the app was killed by the operating system in response to a thermal event. This may be due to an issue with the particular device that this crash occurred on, or the environment it was operated in. For tips on making your app run more efficiently, see [WWDC session](https://developer.apple.com/videos/wwdc/2011/?id=312)
- 0xdead10cc 表示死锁，锁被占用着，一直没有放弃锁导致其他线程无法拥有锁，总结起来就是死锁。
- 0x2bad45ec 表示进程因违反私密信息而被终止

相关连接：
- [理解和分析应用崩溃报告](https://developer.apple.com/library/archive/technotes/tn2151/_index.html)

- [dSYM For Fabric](https://docs.fabric.io/apple/crashlytics/missing-dsyms.html)
