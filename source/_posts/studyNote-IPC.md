---
title: IPC-进程间通信-学习笔记
type: categories
comments: true
date: 2016-10-31 16:06:25
categories: OS Kernal
tags: [进程,Process Communication,进程间通信,IPC]
---

进程间通信的基础原语: 消息、端口、已经确保并发安全的信号量和锁。这篇文章主要对于这些原语的底层实现和端口的内部实现做一些探讨。

Mach任务是一个对应于进程的高层次抽象，Mach任务包含了一个指向自己的IPC namespace（命名空间），在命名空间中保存了自己的端口，此外mach任务也可以获得系统范围内的端口，如：主机端口、特权端口和其它端口。

<!--more-->
### 端口
---

导出给用户空间的端口对象(mach_port_t)实际上是对"真正"端口对象的一个句柄，后者是[ipc_port_t](https://opensource.apple.com/source/xnu/xnu-344/osfmk/ipc/ipc_port.h)，其数据结构如下:
```C
/*
 *  A receive right (port) can be in four states:
 *	1) dead (not active, ip_timestamp has death time)
 *	2) in a space (ip_receiver_name != 0, ip_receiver points
 *	to the space but doesn't hold a ref for it)
 *	3) in transit (ip_receiver_name == 0, ip_destination points
 *	to the destination port and holds a ref for it)
 *	4) in limbo (ip_receiver_name == 0, ip_destination == IP_NULL)
 *
 *  If the port is active, and ip_receiver points to some space,
 *  then ip_receiver_name != 0, and that space holds receive rights.
 *  If the port is not active, then ip_timestamp contains a timestamp
 *  taken when the port was destroyed.
 */

typedef unsigned int ipc_port_timestamp_t;

typedef unsigned int ipc_port_flags_t;

struct ipc_port {

	/*
	 * Initial sub-structure in common with ipc_pset and rpc_port
	 * First element is an ipc_object
	 */
	struct ipc_object ip_object; //ipc对象，初始化子结构跟ipc_pset和rpc_port一致。

	union {
		struct ipc_space *receiver; //指向接收者的IPC指针
		struct ipc_port *destination; //指向全局端口的指针
		ipc_port_timestamp_t timestamp;
	} data;

	ipc_kobject_t ip_kobject;
	mach_port_mscount_t ip_mscount;
	mach_port_rights_t ip_srights;
	mach_port_rights_t ip_sorights;

	struct ipc_port *ip_nsrequest;
	struct ipc_port *ip_pdrequest;
	struct ipc_port_request *ip_dnrequests;

	unsigned int ip_pset_count;
	struct ipc_mqueue ip_messages; //消息队列
	struct ipc_kmsg *ip_premsg;

#if	NORMA_VM
	/*
	 *	These fields are needed for the use of XMM.
	 *	Few ports need this information; it should
	 *	be kept in XMM instead (TBD).  XXX
	 */
	long		ip_norma_xmm_object_refs;
	struct ipc_port	*ip_norma_xmm_object;
#endif

#if	MACH_ASSERT
#define	IP_NSPARES		10
#define	IP_CALLSTACK_MAX	10
	queue_chain_t	ip_port_links;	/* all allocated ports */
	natural_t	ip_thread;	/* who made me?  thread context */
	unsigned long	ip_timetrack;	/* give an idea of "when" created */
	natural_t	ip_callstack[IP_CALLSTACK_MAX]; /* stack trace */
	unsigned long	ip_spares[IP_NSPARES]; /* for debugging */
#endif	/* MACH_ASSERT */
	int		alias;
};
```

### 消息传递的实现
---
用户态的Mach消息传递使用的函数是`mach_msg()`函数，这个函数通过内核的Mach trap调用内核函数`mach_msg_trap()`。然后`mach_msg_trap`调用`mach_msg_overwrite_trap()`,`mach_msg_overwrite_trap`通过测试`MACH_SEND_MSG`和`MACH_RCV_MSG`标志位来判断是发送操作还是接收操作。

下面分析IPC最重要的两个函数`mach_msg_send()`和`mach_msg_receive()`的实现

#### 发送消息

Mach 消息发送的核心逻辑在内核中有两处实现: `mach_msg_overwrite_trap()`和`mach_msg_send()`。后者只用于内核态的消息传递，对用户态不可见。两处实现的逻辑大同小异并遵循以下流程：
- 调用`current_space()`来获取当前的IPC空间。
- 调用`current_map()`来获取当前VM空间([vm_map](https://www.freebsd.org/cgi/man.cgi?query=vm_map&sektion=9&apropos=0&manpath=FreeBSD+11-current))
- 对消息的大小进行正确性检查。
- 计算要分配的消息大小，从send_size参数获得大小再加上硬编码的MAX_TRAILER_SIZE。
- 通过ipc_kmsg_alloc分配消息。
- 复制消息(复制消息send_size字节的部分)，然后在消息头设置msgh_size。
- 复制消息关联的端口权限，然后通过ipc_kmsg_copyin将所有的OOL数据的内存复制到当前的vm_map。 ipc_kmsg_copyin函数调用了ipc_kmsg_copyin_header和ipc_kmsg_copyin_body。
- 调用ipc_kmsg_send()发送消息：
	- 获得msgh_remote_port引用，并锁定端口。
	- 如果该端口是一个内核端口（即端口的ip_receiver是内核的IPC空间），那么通过ipc_kobject_server()函数处理消息。该函数会在内核中找到相应的函数来执行消息，还会生成消息的应答。
	- 不论哪种端口，调用ipc_mqueue_send(),这个函数将消息直接复制到端口的ip_messages队列中并唤醒任何正在等待的线程处理消息。

#### 接收消息

Mach接收消息的方式个发送类似，也体现在内核的两个地方，`mach_msg_overwrite_trap()`用用户态接收请求，而内核通过`mach_msg_receive()`函数接收消息。
- 调用current_space()来获取当前的IPC空间
- 调用current_map()
- 不校对消息大小，因为发送的时候已经校对过了
- 通过调用ipc_mqueue_copyin()获取IPC队列
- 持有当前线程的一个引用。使用当前线程的引用可使它适合使用Mach的续体模型，续体(continuation)模型可以表面维护完整线程栈的必要性。`续体是撒玩意儿博主也弄不明白`
- 调用ipc_mqueue_receive()从队列中取出消息
- 调用mach_msg_receive_results()函数，该函数也可以从续体中调用

