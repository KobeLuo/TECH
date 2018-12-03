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

#### 分析崩溃报告

这部分内容讨论当你获取到`.crash`文件时，如何分析崩溃信息。

##### Header信息
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

#### 常规异常类型解读

##### 内存访问错误 (EXC_BAD_ACCESS、 SIGSEGV、SIGBUS)
进程尝试访问一个无效的内存地址，或者尝试访问没有权限的访问的内存地址都将引发内存访问错误。当内存访问错误发生时，`.crash`文件的`Exception Subtype1`会包含一个`kern_return_t`的描述错误和读取时的错误内存地址。

以下是调试内存访问错误的提示:
- 如果`objc_msgSend`或`objc_release`接近线程回溯的顶部，那么该进程可能尝试访问一个已经被销毁的内存地址。使用Instrument的`Zombies`对于定位crash可能是更好的方式
- 如果`gpus_ReturnNotPermittedKillClient`接近线程回溯的顶部，那么该进程可能是在后台尝试是用OpenGL或Metal来处理渲染工作，该问题的讨论地址[在这](https://developer.apple.com/library/archive/qa/qa1766/_index.html)
- 在项目的Secheme中开启`Address Sanitizer`，当发送内存崩溃时，Xcode会自动提醒

##### 异常退出 (EXC_CRASH、 SIGABRT)
进程异常退出最常见的原因就是一个未被捕获的Objective-C/C++的错误和调用了`abort()`函数
App的扩展程序也可能产生类似的崩溃信息，如果太多次的被初始化。如果一个扩展程序在launch过程中Hang了，Exception Subtype将报`LAUNCH_HANG`，因为扩展程序并没有`main（）`函数，扩展程序或其独立库的时间花销都在静态构造器和`+load()`函数中





相关连接：
- [理解和分析应用崩溃报告](https://developer.apple.com/library/archive/technotes/tn2151/_index.html#//apple_ref/doc/uid/DTS40008184-CH1-SYMBOLICATIONTROUBLESHOOTING)

- [dSYM For Fabric](https://docs.fabric.io/apple/crashlytics/missing-dsyms.html)
