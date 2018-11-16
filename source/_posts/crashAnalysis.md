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


相关连接：
- [理解和分析应用崩溃报告](https://developer.apple.com/library/archive/technotes/tn2151/_index.html#//apple_ref/doc/uid/DTS40008184-CH1-SYMBOLICATIONTROUBLESHOOTING)

- [dSYM For Fabric](https://docs.fabric.io/apple/crashlytics/missing-dsyms.html)
