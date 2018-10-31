---
title: Mach 原语 笔记-基础篇
type: categories
comments: true
date: 2018-10-31 10:21:59
categories: Mac OS
tags: [Mach,MAC OS,Mac内核]
---

### [Mach](https://zh.wikipedia.org/wiki/Mach) 概述
---

#### Mach设计原则
Mac OS X采用Mach作为锡系统的内核，其源头可以追溯到乔老爷创立的NeXT。Mach采用了极简主义概念:
``
具有一个简单最小的核心，支持面向对象的模型，使得独立的具有良好定义的组件可以通过消息的方式互相通信。
``
Mach只提供了一个极简的模型，操作系统本身可以在这个模型基础上实现，OS X的[XNU](https://en.wikipedia.org/wiki/XNU)是UNIX（[FreeBSD](https://zh.wikipedia.org/zh-hans/FreeBSD) 4.4）在Mach上的一个具体实现，Windows也采用了一些Mach的原则，不过其实现方式与Mac OS则完全不同。

Mach内核成为了一个底层的基础，它只关心驱动操作系统的最少需求，其余的功能则需要由上层来实现，尽管Mach对用户态也是可见的，使用Mach都是实现了深层次的核心功能，在这个基础上可以实现更大的内核，而Mach则是内核中的内核，``XNU的官方API是BSD的POSIX API,Apple保持了Mach绝对的极简，基于Mach外层则有丰富的Cocoa API来支撑，因此Mach是Mac OS X操作系统中最关键最基础的部分``

<!--more-->

在Mach的所有都是通过自己的对象实现的。进程、线程、虚拟内存其实都是对象，所有的对象都有自己的属性，所谓的对象其实就是C语言的结构体加上函数指针实现的。


Mach的独特之处在于选择了通过消息传递的方式实现对象与对象之间的通信。而其他架构中一个对象要访问另一个对象则需要一个接口来实现。而Mach对象不能直接调用另一个对象，而是通过消息传递的方式，源发送一条消息，这条消息被加入到目标对象的队列中等待处理，类似，消息处理中可能会产生一个应答，该应答则通过另一条消息被发送回源对象，消息发送的方式是以FIFIO的方式保证了传输的可靠性，而内容则由发送者和接收者协商。

#### Mach 设计目标

其最重要的目标是将所有的功能都移出内核，将功能放在用户态中去实现，保持内核极简，其主要功能如下:

- 控制点和执行单元(线程)管理
- 线程和线程组的资源分配
- 虚拟内存的分配和管理
- 底层物理资源的分配(即CPU、内存和其他任何物理设备)

Mach只提供了实行策略的方法，而不提供策略本身，Mach也不会识别任何安全特性、优先级和选项(Options)，所有这些都需要上层去定义和实现。

Mach设计中有一个强大的优点:**多处理(multi process)**。
内核中大部分的功能都是由独立的组件实现，组件之间的传递具有良好定义的消息，之间没有公共作用域，因此，没有必要所有的组件都在同一个处理器上执行，甚至不要求在同一台计算机上执行。
**理论上：Mach可以轻松扩展成计算机集群使用的操作系统。**

### Mach消息
---

消息是Mach中最基本的概念，通过短点(endpoint)或端口(port)之间传递，消息是Mach IPC的核心模块。

#### 简单消息
一条消息就像一个网络数据包，通过固定的包头进行封装，定义为BLOB(binary large object,二进制大对象)，在Mach中，消息定义在`<mach/message.h>`中
```c
typedef struct 
{	
  mach_msg_header_t		header;
  mach_msg_body_t		body;
}mach_msg_base_t;
```

而消息头是强制要求的，其中定义了相关的元数据，内容如下：
```c
typedef	struct 
{
  mach_msg_bits_t	msgh_bits; 			//消息头的标识位
  mach_msg_size_t	msgh_size;			//大小，以字节为单位
  mach_port_t		msgh_remote_port;	//目标(发出的消息)或源(接收的消息)
  mach_port_t		msgh_local_port;	//源(发出的消息)或目标(接收的消息)
  mach_port_name_t	msgh_voucher_port;	//
  mach_msg_id_t		msgh_id;			//唯一ID
} mach_msg_header_t;
```
一条消息就是一个BLOB,通过端口发送到另一个端口并带有可选的标识；
消息还可以选择带有一个消息尾(trailer),其定义如下:
```c
typedef	unsigned int mach_msg_trailer_type_t;
typedef	unsigned int mach_msg_trailer_size_t;

typedef struct 
{
  mach_msg_trailer_type_t	msgh_trailer_type;
  mach_msg_trailer_size_t	msgh_trailer_size;
} mach_msg_trailer_t;

```
每一种trailer类型都定义了一种特殊的trailer格式，这些格式都是为未来可以实现扩展的，下面是一些已经定义好的类型：

| trailer | 用途 |
| :------ | :------ |
| mach_msg_trailer_t | 空trailer |
| mach_msg_security_trailer_t | 发送者安全令牌 |
| mach_msg_seqno_trailer_t | 顺序编号 |
| mach_msg_audit_trailer_t，mach_msg_context_trailer_t | 审计令牌(用于BSM) |
| mach_msg_mac_trailer_t | MAC策略标签 |
应答消息和内核消息使用到了trailer.

#### 复杂消息
除了简单的消息外，有一些带有额外的字段和结构的消息被称为"复杂消息"，它们是通过消息头标志中的MACH_MSGH_BITS_COMPLEX位来表示的，而且数据结构也不同：
``
消息头后面跟着一个描述符计数字段，再接一个串行化的描述符
``

| trailer | 用途 |
| :------ | :------ |
| MACH_MSG_PORT_DESCRIPTOR | 传递一个端口权限 |  
| MACH_MSG_OOL_DESCRIPTOR | 传递 out-of-line 数据 |
| MACH_MSG_OOL_PORTS_DESCRIPTOR | 传递 out-of-line 端口 |
| MACH_MSG_OOL_VOLATILE_DESCRIPTOR | 传递有可能发生变化(volatile)的out-of-line数据 |
以上是一些已规定的复杂消息描述符，其中`out-of-line`是Mach消息的一个重要特性，允许添加各种数据的分散指针，类似于电子邮件添加附件的功能，其64位的数据结构如下:
```C
typedef struct
{
  void*				address;				//指向数据的指针
#if !defined(__LP64__)
  mach_msg_size_t       	size;			//数据大小
#endif

  boolean_t     		deallocate: 8;		//发送之后是否解除分配
  mach_msg_copy_options_t       copy: 8;	//复制指令
  unsigned int     		pad1: 8;			//预留参数
  mach_msg_descriptor_type_t    type: 8;	//MACH_MSG_OOL_DESCRIPTOR

#if defined(__LP64__)
  mach_msg_size_t       	size;
#endif
} mach_msg_ool_descriptor_t;
```
OOL描述了要附加的数据的地址和大小，一级如何处理数据的指令，例如是否可以解除分配，以及复制选项(如物理内存和虚拟内存的复制)。
OOL描述符常用语传递大块的数据，能避免昂贵的复制操作。

#### 发送消息
Mach消息的发送和接收都是通过同一个API函数mach_msg()来完成的，该函数在用户态和内核态都有实现，其原型如下:
```C
/*
 *	Routine:	mach_msg
 *	Purpose:
 *		Send and/or receive a message.  If the message operation
 *		is interrupted, and the user did not request an indication
 *		of that fact, then restart the appropriate parts of the
 *		operation silently (trap version does not restart).
 */
__WATCHOS_PROHIBITED __TVOS_PROHIBITED
extern mach_msg_return_t	mach_msg(
					mach_msg_header_t *msg,
					mach_msg_option_t option,
					mach_msg_size_t send_size,
					mach_msg_size_t rcv_size,
					mach_port_name_t rcv_name,
					mach_msg_timeout_t timeout,
					mach_port_name_t notify);
```
```C
/*
 *	Routine:	mach_msg_overwrite
 *	Purpose:
 *		Send and/or receive a message.  If the message operation
 *		is interrupted, and the user did not request an indication
 *		of that fact, then restart the appropriate parts of the
 *		operation silently (trap version does not restart).
 *
 *		Distinct send and receive buffers may be specified.  If
 *		no separate receive buffer is specified, the msg parameter
 *		will be used for both send and receive operations.
 *
 *		In addition to a distinct receive buffer, that buffer may
 *		already contain scatter control information to direct the
 *		receiving of the message.
 */
__WATCHOS_PROHIBITED __TVOS_PROHIBITED
extern mach_msg_return_t	mach_msg_overwrite(
					mach_msg_header_t *msg,
					mach_msg_option_t option,
					mach_msg_size_t send_size,
					mach_msg_size_t rcv_size,
					mach_port_name_t rcv_name,
					mach_msg_timeout_t timeout,
					mach_port_name_t notify,
					mach_msg_header_t *rcv_msg,
					mach_msg_size_t rcv_limit);
```

该函数接受一个消息缓冲区参数，对于发送操作是一个输入指针，对于接收操作是一个输出指针。该函数还有一个姊妹函数`mach_msg_overwrite`，允许调用者指定另外两个参数:一个是`mach_msg_header_t*`指向接收缓冲区，一个是`mach_msg_size_t`用于表示缓冲区大小。
无论哪个函数，都可以通过按位操作选项来指定，具体的操作如下表：

| 选项标志位 | 用途 |
| :------ | :------ |
| MACH_RCV_MSG | 接收一条消息放在msg缓冲区 |
| MACH_RCV_LARGE | 如果接收缓冲区太小，则将过大的消息放在队列中，并且出错返回MACH_RCV_TOO_LARGE。在这种情况下，只返回消息头(指定消息的大小)，因此调用者可以分配更多的内存 |
| MACH_RCV_TIMEOUT | 单位是毫秒，如果接收超时，则出错返回MACH_RCV_TIMED_OUT。timeout值可以指定为0 |
| MACH_RCV_NOTIFY | 带通知的接收操作 |
| MACH_RCV_INTERRUPT | 允许操作被打断(返回MACH_RCV_INTERRUPT) |
| MACH_RCV_OVERWRITW | 在mach_msg_overwrite中，指定额外的参数：接收缓冲区参数，输入还是输出 |
| MACH_SEND_MSG | 发送msg缓冲区中的消息 |
| MACH_SEND_INTERRUPT | 允许发送操作被打断 |
| MACH_SEND_TIMEOUT | 发送超时，单位是毫秒。如果发送timeout秒后还未发送完成，则返回MACH_SEND_TIME_OUT |
| MACH_SEND_NOTIFY | 向通知端口通知消息的传递 
| MACH_SEND_ALWAYS | 内部使用 |
| MACH_SEND_TRAILER | 表示一个已知的Mach trailer位于位置大小偏移的位置(也就是紧跟着消息缓冲区之后的位置，有点晦涩，笔者没看明白) |
| MACH_SEND_CANCEL | 取消一条消息(Lion中已经被移出了) |
Mach消息原本是为真正的微内核框架而设计的，也就是说`mach_msg()`必须在发送者和接收者之间复制消息所在的内存，这种实现方式忠于微内核的范式，但事实证明：频繁的复制内存所带来的性能消耗是无法忍受的。
因此，XNU通过单一内核方式:所有的内核组件都共享同一个地址空间，这样传递消息的过程中只需要传递消息的指针的就可以了，从而省去了昂贵的内存复制操作。

为了实现消息的发送和接收，`mach_msg()`函数调用了一个Mach trap（[Mach 陷阱](http://www.kobeluo.com/TECH/2018/10/31/mach-trap/)）,在用户态调用`mach_msg_trap()`函数会引发陷阱机制，切换到内核态，而在内核态中，内核实现的`mach_msg()`会完成实际的工作。

#### 端口
端口是一个32位整型的标识符，不能按整数来操作，而是要按照透明的对象来操作。
``
像一个端口发送消息实际是将消息放在一个队列中，直到消息能被接收者处理。
``
所有的Mach原生对象都是通过对应的端口访问的，查找一个对象的句柄(Handle)时，实际上请求的是这个对象端口的句柄，访问端口是通过访问端口权限的方式进行的，Mach端口权限的定义如下:

| MACH_PORT_RIGHT_ | 含义 |
| :------ | :------ |
| SEND | 向端口发送消息。允许多个发送者 |
| RECEIVE | 从端口读取消息，实际上这是对端口的所有权 |
| SEND_ONCE | 只发送一次消息，该权限在使用后立即被撤销(revoke)，成为DEAD_NAME |
| PORT_SET | 同时拥有多个端口的接受权限 |
| DEAD_NAME | 端口在SEND_ONCE之后用完了权限 |

关键是SEND和RECEIVE,而SEND_ONCE跟SEND一样，只不过只能发送一次。MACH_PORT_RIGHT_RECEIVE权限的持有者实际上是端口的所有者，这是允许从该端口读取队列消息的唯一实体。
<mach/mach_port.h>中的函数可以用于操纵任何端口，甚至可以在任务之外操纵。其中，`mach_port_names`函数可以导出给定任务的端口空间名称。

端口和权限也可以从一个实体传递到另一个实体。实际上，通过复杂消息将端口从一个任务传递到另一个任务并不罕见，这是IPC设计中的一个非常强大的特性，有点类似于UNIX中的`domain socket`允许在进程间传递描述符。
Lion允许UNIX文件描述符和Mach端口相互转换。这些对象称为fileport，主要有通知系统使用。

Mach通过端口命名服务器注册全局的端口-即系统范围内的端口。在XNU中，这个“自举服务器”正是PID为1的launchd(8)，该进程注册自举服务器端口，由于系统的所有进程都是launchd的后代，因此从诞生起都集成了这个端口。

#### Mach 接口生成器(MIG)

Mach没有使用专门的端口映射器(不过launchd(8)处理了一部分端口映射的逻辑）,但是Mach中有一个类似于[rpcgen](https://en.wikipedia.org/wiki/RPCGEN)的组件，即Mach接口生成器(Mach Interface Generator)，简称MIG。rpcgen在经典UNIX中的SUN-RPC中，通过rpcgen编译器从IDL(Interface Definition Language, IDL)生成代码。
在/usr/include/mach目录下，可以看到一些.defs文件，这些文件包含了各种Mach子系统的IDL定义。
