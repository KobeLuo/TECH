---
title: Mach 同步机制 (未完结)
type: categories
comments: true
date: 2018-10-31 16:59:31
categories: Mac OS 
tags: [Mach同步机制，同步，mutex，自旋锁，信号量]
---

消息传递机制是 Mach IPC架构中的一个组件，另一个组件是同步机制(synchronization)，同步机制用于判定多个并发的操纵时，如何访问共享资源的问题。
同步机制的本质是:
``
排他访问的能力，即：在使用一个资源时，排除其它对象对该资源的访问的能力。
``
最基本的同步原语是互斥(mutual exclusion)对象，也叫互斥体(mutex)。互斥体只不过是内核内存中的普通变量，硬件必须对这些变量进行原子(atomic)操作。意思是对互斥体的操作决不允许被打断，即使硬件中断也不能打断，在SMP系统上，互斥体还有一个要求就是要求硬件实现某种屏障(fence或barrier)。

<!--more-->

下面是一些同步原语：

| 对象 | 实现的文件 | 所有者 | 可见性 |  等待 |
| ------ | ------ | ------ | ------ | ------ |
| 互斥体(lck_mtx_t) | i386/i386_locks.c | 1个 | 内核态 | 阻塞 |
| 信号量(semaphore_t) | kern/sync_sema.c | 多个 | 用户态 | 阻塞 |
| 自旋锁(hw_lock_t等) | i386/i386_locks.s | 1个 | 内核态 | 忙等 |
| 锁集(lock_set_t) | kern/sync_lock.c | 1个 | 用户态 | 阻塞(同互斥体) |

Mach锁由两个层次组成：
- 硬件相关层: 通过硬件的特性，通过特定的汇编指令实现的原子性和互斥性。
- 硬件无关层: 通过API包装硬件特定的调用，是通过简单的宏来实现的；这些API使得基于Mach的上层完全不用关心细节的实现。

### [锁组对象](https://opensource.apple.com/source/xnu/xnu-792.6.76/osfmk/kern/locks.h.auto.html)

大部分Mach的同步对象都不是独立存在的，而是属于`lck_grp_t`对象,``typedef struct __lck_grp__ lck_grp_t;``;
锁组(lock group)对象定义结构如下：
```C
#define	LCK_GRP_MAX_NAME	64

typedef	struct _lck_grp_ {
	queue_chain_t		lck_grp_link;
	unsigned int		lck_grp_refcnt;
	unsigned int		lck_grp_spincnt;
	unsigned int		lck_grp_mtxcnt;
	unsigned int		lck_grp_rwcnt;
	unsigned int		lck_grp_attr;
	char				lck_grp_name[LCK_GRP_MAX_NAME];
	lck_grp_stat_t		lck_grp_stat;
} lck_grp_t;

#define LCK_GRP_NULL	(lck_grp_t *)0

#else
typedef struct __lck_grp__ lck_grp_t;
#endif
```
`lck_grp_t`就是一个链表中的一个元素，有一个指定的名字，以及最多三种类型的锁:自旋锁、互斥体和读写锁。其中`lck_grp_stat_t`提供锁组的统计信息功能，用于调试和同步相关的问题。`lck_grp_attr`可以用来设置一个LCK_ATTR_DEBUG属性。

锁组的创建和销毁API如下：
```C
//创建新的锁组； 锁组通过grp_name标识，拥有attr指定的属性，一般情况下，都是通过lck_grp_attr_alloc_init()设置默认属性。
extern void lck_grp_init(lck_grp_t *grp, const char *grp_name, lck_grp_attr_t *attr);
//接触分配锁组
extern void lck_grp_free(lck_grp_t *grp);

```
在Mach和BSD中，几乎每个子系统在初始化时都会创建一个自己使用的锁组。


### 互斥体对象

互斥体(lck_mtx_t)是最常用的锁对象,它必须属于一个锁组，相关的API如下表：

```C
//通过指定的grp和attr,创建并初始化新的互斥体对象
extern lck_mtx_t *lck_mtx_alloc_init(lck_grp_t *grp, lck_attr_t *attr);

//初始化已经分配的互斥体lck.
extern void lck_mtx_init(lck_mtx_t *lck, lck_grp_t *grp, lck_attr_t *attr);

//对互斥体上锁，如果重复上锁会产生阻塞
extern void lck_mtx_lock(lck_mtx_t *lck);

//对互斥体尝试上锁，如果不成功则返回失败
extern boolean_t ck_mtx_try_lock(lck_mtx_t *lck);

//对互斥体解锁
extern void lck_mtx_unlock(lck_mtx_t *lck);

//将互斥体标记为销毁，互斥体将不可以继续使用，但依然占据内存空间，可以重新对其初始化。
extern void lck_mtx_destroy(lck_mtx_t *lck,lck_grp_t *grp);

//将互斥体标记为销毁，并释放其内存空间。
extern void lck_mtx_free(lck_mtx_t *lck,lck_grp_t *grp);

//将当前线程置于睡眠状态，直到lck变为可用状态
extern wait_result_t lck_mtx_sleep(lck_mtx_t *lck, ck_sleep_action_t lck_sleep_action,
				   event_t event, wait_interrupt_t interruptible);

//将当前线程置于睡眠状态，直到lck变为可用状态或到达deadline的时限
extern wait_result_t lck_mtx_sleep_deadline(lck_mtx_t *lck,
				   lck_sleep_action_t lck_sleep_action, event_t event,
				   wait_interrupt_t interruptible, uint64_t deadline);

```
互斥锁有一个很大的缺点：``就是一次只能由一个线程持有锁对象。``
在很多情况下，多线程可能对资源请求只读的访问。在这些情况下，使用互斥体会阻止并发的访问，即使这些线程之间并不会相互影响，这就带来了性能的瓶颈。


### 读写锁对象
读写锁(read-write lock)的设计初衷就是为了解决互斥锁的缺点。它是更智能的互斥锁，能够区分读写访问，多个只读的线程可以同时持有读写锁，而一次只允许一个写的线程可以获得锁，当一个写的线程持有锁是，其余线程的锁都将被阻塞。
跟mutex lock相似，下面是读写锁相关的API:
```C
extern lck_rw_t *lck_rw_alloc_init(lck_grp_t *grp, lck_attr_t *attr);

extern void lck_rw_init(lck_rw_t *lck, lck_grp_t *grp, lck_attr_t *attr);

extern void lck_rw_lock_shared(lck_rw_t *lck);
extern void lck_rw_unlock_shared(lck_rw_t *lck);

extern void lck_rw_lock_exclusive(lck_rw_t *lck);
extern void lck_rw_unlock_exclusive(lck_rw_t *lck);

//加锁
//如果当前线程是读，当有写的线程持有锁时，当前线程调用会被阻塞
//如果当前线程是写，当有其他线程获得锁时，调用会被阻塞
//这个API等同于lck_rw_lock_shared + lck_rw_lock_exclusion 
extern void lck_rw_lock(lck_rw_t *lck, lck_rw_type_t lck_rw_type);

////这个API等同于lck_rw_unlock_shared + lck_rw_unlock_exclusion
extern void lck_rw_unlock(lck_rw_t *lck, lck_rw_type_t lck_rw_type);

extern void lck_rw_destroy(lck_rw_t *lck, lck_grp_t *grp);

extern void lck_rw_free(lck_rw_t *lck, lck_grp_t *grp);

//action 可以是LCK_SLEEP_SHARED 和 LCK_SLEEP_EXCLUSION.
extern wait_result_t lck_rw_sleep(lck_rw_t *lck, lck_sleep_action_t lck_sleep_action,
					  event_t event, wait_interrupt_t interruptible);


extern wait_result_t lck_rw_sleep_deadline(lck_rw_t *lck, lck_sleep_action_t lck_sleep_action,
				  event_t event, wait_interrupt_t interruptible, uint64_t deadline);
```
### 信号量对象
Mach提供了信号量(Semaphore)，信号量是一种泛化的互斥体，互斥体只能是0和1，而信号量是可以将取值达到某个整数时就允许持有信号量的线程同时执行的这样一种互斥体，信号量在用户态使用，而互斥体只能在内核态使用。

{% note info %}
Mach中的信号量和POSIX中的信号量不同，API也不同，因此两者不相容，在XNU上，POSIX信号量的底层实现是通过Mach的信号量实现的。
POSIX中的`sem_open()`函数其实调用了Mach的`semaphore_create()`函数
{% endnote %}

信号量本身是一个不可锁的对象，拥有很小的结构体，包含了所有者和端口的引用，还包括了一个wait_queue_t用来保证正在等待这个信号量的线程的链表，
wait_queue_t会通过硬件锁的方式锁定。
下面是信号量对象的结构体:
```C

#ifdef MACH_KERNEL_PRIVATE

typedef struct semaphore {
	queue_chain_t	  task_link;  /* chain of semaphores owned by a task */
	struct wait_queue wait_queue; /* queue of blocked threads & lock     */
	task_t		  owner;      /* task that owns semaphore            */
	ipc_port_t	  port;	      /* semaphore port	 		     */
	int		  ref_count;  /* reference count		     */
	int		  count;      /* current count value	             */
	boolean_t	  active;     /* active status			     */
} Semaphore;

#define semaphore_lock(semaphore)   wait_queue_lock(&(semaphore)->wait_queue)
#define semaphore_unlock(semaphore) wait_queue_unlock(&(semaphore)->wait_queue)

extern void semaphore_init(void);

extern	void		semaphore_reference	(semaphore_t semaphore);
extern	void		semaphore_dereference	(semaphore_t semaphore);

#endif /* MACH_KERNEL_PRIVATE */
```


下面列出了Mach中 信号量的相关API:
```C

/*
 *	Routine:	semaphore_create
 *
 *	Creates a semaphore.
 *	The port representing the semaphore is returned as a parameter.
 *	为task创建一个信号量new_semaphore,policy表示阻塞的线程如何被唤醒，使用的是和锁策略相同的值。
 */
kern_return_t semaphore_create(task_t task, semaphore_t *new_semaphore, int policy, int value)


/*
 *	Routine:	semaphore_destroy
 *
 *	Destroys a semaphore.  This call will only succeed if the
 *	specified task is the SAME task name specified at the semaphore's
 *	creation.
 *
 *	All threads currently blocked on the semaphore are awoken.  These
 *	threads will return with the KERN_TERMINATED error.
 */
kern_return_t semaphore_destroy( task_t task, semaphore_t semaphore)


/*
 *	Routine:	semaphore_signal
 *
 *		Traditional (in-kernel client and MIG interface) semaphore
 *		signal routine.  Most users will access the trap version.
 *
 *		This interface in not defined to return info about whether
 *		this call found a thread waiting or not.  The internal
 *		routines (and future external routines) do.  We have to
 *		convert those into plain KERN_SUCCESS returns.
 *		增加信号量计数，如果计数器大于等于0，则唤醒一个阻塞的线程。
 */
kern_return_t semaphore_signal(semaphore_t semaphore)


/*
 *	Routine:	semaphore_signal_all
 *
 *	Awakens ALL threads currently blocked on the semaphore.
 *	The semaphore count returns to zero.
 *	将计数器值置为0，并唤醒所有阻塞的线程。
 */
kern_return_t semaphore_signal_all(semaphore_t semaphore)

/*
 *	Routine:	semaphore_wait
 *
 *	Traditional (non-continuation) interface presented to
 * 	in-kernel clients to wait on a semaphore.
 * 	减去一个信号量计数，如果小于0，则阻塞知道计数器再次变为非负数。
 */
kern_return_t semaphore_wait(semaphore_t semaphore)

```
信号量的属性可以让信号量转换为端口，也可以由端口转换回来，[ipc_sync.c](https://opensource.apple.com/source/xnu/xnu-792.6.76/osfmk/kern/ipc_sync.c.auto.html)中定义了这些操作的函数，但该功能并不为用户态暴露，内核态也未使用。


### 自旋锁对象

### 锁集对象