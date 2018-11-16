---
title: 细数Mac OS/iOS 系统下的锁(lock)
type: categories
comments: true
date: 2018-11-13 11:30:49
categories: Swift
tags: [OS Lock, 锁, locks, osunfairlock,mutex, semaphore, nslock, NSConditionLock]
---

### 前言

最近一段时间，博主都在做代码性能上的一些优化工作，其中就包括了对Mac OS/iOS锁这一部分的优化，趁此机会，也比较系统的测试了各种用户态的锁分别在单个线程和多个线程中的表现。之所以叫用户态的锁，是因为Mach内核部分其实还有一部分内核态的锁，它并不为用户态所开放，我们一般也使用不到。

对同一个锁对象的加解锁必须保持在同一线程执行，如果尝试在不同线程去加解锁将会引发一个运行时的错误。

#### 用户态可用的锁

用户态的锁大概有以下:
- NSLock
- NSRecusiveLock
- pthread_mutex_t 
- pthread_mutex_t (recusive)
- NSCondition
- NSConditionLock
- dispatch_semaphore_t
- os_unfair_lock
- OS_SPLINK_LOCK
- @synchronized

<!--more-->

#### 内核态的锁

而内核态的锁大概有以下几类: 
- lck_mtx_t (互斥体) 
互斥体是内核内存中的普通变量，是一个机器字大小的整数，但是它要求硬件必须对这些互斥体进行原子(atomic)操作
- lck_rw_t （读写锁） 
一个更高级的互斥体，多个读者可以同时持有锁，而同时只能有一个写者持有该锁。一旦写者持有该锁，其它线程全部都将被阻塞
- hw_lock_t （自旋锁）
内核态的自旋锁跟用户态的自旋锁(OS_SPLIN_LOCK)并不是一个概念，内核态的自旋锁实际上是为了解决互斥体在频繁的线程切换过程中带来的开销而设计的，当锁被阻塞时，它不会主动交出线程的处理器，而处于一种重复尝试访问锁的忙等状态(busy-wait)，如果当前访问的锁的持有者在它访问几个周期后就放弃持有了，那么它的效率就比较高，省去了很多上下文切换带来的开销，同时，他也可能造成死锁，整个系统可能会因此而停滞。
- semaphore (信号量) 
其实它是一个用户态的锁，Mach中的信号量跟POSIX中的信号量不是一个概念，API也不一样，但是XNU上POSIX信号量的底层是通过Mach信号量来实现的。

关于内核态的同步机制，博主也写了一篇[学习笔记](http://www.kobeluo.com/TECH/2018/10/31/mach-synchronization/),有兴趣可以了解一下。

### 锁的测试结果

针对用户态可用的锁，博主做了一个较为详细的测试，由于使用的是Swift来测试锁的性能，所以在Objective-C中使用的`@synchronized`并没有在本次测试范围，实际上@synchronized可能是最消耗性能的一种锁。，测试源码[在这](https://github.com/KobeLuo/DemoRepo/blob/master/OSLockCompareDemo/OSLockCompareDemo/OSLockCompare.swift)

简单看以下测试的源代码片段
```Swift
private func testSemaphore() {
        
        for index in 1...repeatTimes {
            
            let start = CACurrentMediaTime()
            
            sema.wait()
            //如果要去掉上下文，则注释该print
            print("index: \(index) ")
            sema.signal()
            
            let end = CACurrentMediaTime()
            self.recordTimeFor(type: OSLockType.l_Semaphore, time: end - start)
        }
}
```
以上代码时测试信号量(semaphore)时的核心代码，该段代码有两种测试方式，一种是保留上下文，另外一种则是去掉上下文。

#### 测试结果

以下是测试结果的汇总：

- 测试环境:   Mac OS X 10.14.1 Beta (18B57c)， Xcode: Version 9.4.1 (9F2000)
- 为了全部数据格式统一和去掉上下文的数据更准确，本次测试所有时间单位统一为(us/10),即0.1微妙为单位。
- 对于单线程的条形图，数据表示每一次加锁和解锁的平均消耗
- 对于多线程的条形图，数据表示5个线程完成一次加锁和解锁的平均消耗

- 测试发现`OSUnfairLock`、`semaphore`、`mutex`在各种环境下的表现最稳定，性能差距不大，应该作为锁的首选考虑。

本次测试博主尝试了Repeat不同的次数下，各类锁的耗时情况，发现各类锁的耗时大小顺序并不是固定的，并且差异挺大，仅仅只有单线程且去掉上下文的情况下，测试结果相对稳定，博主猜测大概是因为测试时电脑瞬时性能、CPU使用情况和内核调度的情况有关系，具体原因不敢妄下结论。


#### 测试结果总结

**测试结果只能从某个方面反映出锁的效率，也许它并不是最准确的结果，它是在特定环境下的真实测试结果。**

去掉上下文的测试结果，仅仅只能说明锁本身的实现复杂度和内部的执行效率,它并不能说明锁在实际使用过程中，结合上下文的执行效率，只能作为理论依据。

#### 单线程
关于多线程的测试，其核心片段代码如下:
```Swift
class func startThreadCompare(_ testTimes: Int) -> Bool {
    //initial class
    let compare = OSLockCompare.init(testTimes: testTimes)
    //test locks
    compare.testLocks()
    
    return true
}

```

##### 单线程，去掉上下文

![测试元数据](singleAndContextResign.png)
![测试图表](contextResignSingle.png)

从元数据清单表格上可以看出，随着Repeat次数的逐步增大，信号量(`Semaphore`)的执行效率逐渐变得更优优势，其次是`SpinLock`，`mutex`，`unfairLock`，效率最低的是`NSConditionLock`
至于为什么量级越大，不同的锁在纯粹的加减锁过程中的效率表现会出现差异，有待进一步研究，同时也希望各路大神指点一二。

##### 单线程，保留上下文

![测试元数据](singleAndContextKeep.png)
![测试图表](contextKeepSingle.png)

在保留上下文的情况下，使用相同的方式去测试单线程下各类锁的性能消耗，得到了一个与去掉上下文完全不同的结果，在仅仅只执行`print`函数的上下文情况下，发现OSUnfairLock的效率是最高的，其次是`mutex`、`semaphore`，最差的是`OSSpinLock`。

单线程测试发现：
- 在低频次的加减锁情况下，`unfairLock`的表现是最好的。
- 在高频次的加减锁情况下，`semaphore`的表现是最好的。

同时发现其它的一些大牛写的博文跟这里的结果并不一致，这可能跟测试方式、当前OS系统运行情况等多方面有关系，博主所呈现的是真实的测试数据。

#### 多线程

关于多线程的测试，其核心片段代码如下:
```Swift
class func startMultiThreadCompare(_ testTimes: Int, threadCount: Int, ci: @escaping invokeBlock) {
        
    let compare = OSLockCompare.init(testTimes: testTimes, threadCount)
    let labelbase = "com.compare.oslock"
    
    compare.invoke = ci
    
    var subQueues = [DispatchQueue]()
    
    for index in 1...threadCount {
        
        let label = labelbase + ".\(index)"
        let seriaQueue = DispatchQueue.init(label: label)
        
        seriaQueue.async { compare.testLocks() }
        
        subQueues.append(seriaQueue)
    }
    
    compare.queues = subQueues
}
```

测试数据中的多线程的*Average Per time*是指多个线程同时完成一次加减锁所需要的时间。本例是5个线程

##### 多线程，去掉上下文

![测试元数据](multiAndContextResign.png)
![测试图表](contextResgnMulti.png)

通过测试数据可以发现，
- `OSUnfairLock`在5个线程同时测试锁的性能时，表现最优越，其平均消耗远低于其它锁，信号量`Semaphore`次之，`mutex`紧随其后。
- 而类似于`NSLock`,`NSConditionLock`等更上层的锁在多线程环境下的综合表现则很一般。单线程的锁更多的是作为一种理论而存在，而多线程的测试数据则重要得多，它可能更接近于我们日常开发的需要。
- 对比单线程，去掉上下文的数据，多线程的耗时多了很多，除了多个线程同时加减锁所耗费的时间外，更多的消耗则用在了线程之间的来回切换。

##### 多线程，保留上下文

![测试元数据](multiAndContextKeep.png)
![测试图表](contextKeepMulti.png)

在这组综合测试中，`OSUnfairLock`依然稳居榜首，而`mutex`和`semaphore`则排在稍微靠后的位置上，博主猜测可能是因为频繁的线程切换导致的性能损失。

### 各类锁介绍

Mac OS/iOS系统下，用户态的锁使用方式都相对简单，大部分都进行了封装，像`NSLock`,`NSConditionLock`,`NSRecusiveLock`等等，他们只暴露必要的接口，而降实现细节全部隐藏起来由内部函数去处理，这些锁在ARC系统下不需要管理内存；也有一部分较为底层的锁，像`pthread_mutex`，`OSUnfairLock`等，但他们的使用都非常的方便简单。

#### OSSpinLock 不再安全的自旋锁

POSIX下的自旋锁的设计原理跟Mach内核的自旋锁原理一致。

苹果的工程师已经[证实](https://lists.swift.org/pipermail/swift-dev/Week-of-Mon-20151214/000372.html)了OSSpinLock在多种优先级并存的环境中同时访问自旋锁由于优先级反转问题致使持有自旋锁的低优先级线程无法获取CPU资源，导致高优先级线程产生忙等的问题。具体请看ibireme大神[这篇文章](https://blog.ibireme.com/2016/01/16/spinlock_is_unsafe_in_ios/),

结论是：如果无法确定当前多线程环境的所有线程是同一个优先级，请勿使用OSSpinLock.

Apple在OSX 10.12/iOS 10上使用`OSUnfairLock`替代了`OSSpinLock`,后面将会提及`OSUnfaieLock`相关消息及使用方法。


其使用方法如下:
```Swift

var splinLock = OS_SPINLOCK_INIT

//mark: test locks
private func testOSSpinlock() {
    
    OSSpinLockLock(&splinLock)

        //code block in here...

    OSSpinLockUnlock(&splinLock)
}

```

#### OSUnfairLock 

`OSUnfairLock`是在Mac OSX 10.12上，Mac给出了替换`OSSpinLock`的方案，它也是一个底层的锁对象，与`OSSpinLock`不同的是，他不再是采用忙等的方式，而是睡眠，知道该锁被unlock时被内核唤醒。官方文档还提到
{% note info %}
A lock should be considered opaque and implementation-defined. Locks contain thread ownership information that the system may use to attempt to resolve priority inversions.

//一个锁应该被是不透明的且有实现的定义，锁对象包括的拥有者信息可以用来解决优先级反转问题。
{% endnote %}

其使用方式如下:
```Swift

var unfair = os_unfair_lock()
private func testOSUnfairLock() {
    
    os_unfair_lock_lock(&unfair)
    
    //your code block in here.
    
    os_unfair_lock_unlock(&unfair)
}

```

#### pthread_mutex_t 

`pthread_mutex_t`是 linux系统下的互斥体，属于底层锁，但它跟Mach内核太的互斥体不是一回事，实际上POSIX下的互斥体的底层实现应该是使用了Mach内核的互斥体(`lck_mtx_t`),，POSIX下的互斥体文档中有很多函数实现，以下仅简单说明重要的函数使用。
```Swift
//初始化互斥体
public func pthread_attr_init(_: UnsafeMutablePointer<pthread_attr_t>) -> Int32
//初始化一个pthread的属性
public func pthread_attr_init(_: UnsafeMutablePointer<pthread_attr_t>) -> Int32
//销毁一个曾经初始化的属性
public func pthread_attr_destroy(_: UnsafeMutablePointer<pthread_attr_t>) -> Int32
///设置pthread属性的类型,分别是
/// PTHREAD_MUTEX_NORMAL, PTHREAD_MUTEX_ERRORCHECK
/// PTHREAD_MUTEX_DEFAULT, PTHREAD_MUTEX_RECURSIVE
public func pthread_mutexattr_settype(_: UnsafeMutablePointer<pthread_mutexattr_t>, _: Int32) -> Int32

//初始化mutex
public func pthread_mutex_init(_: UnsafeMutablePointer<pthread_mutex_t>, _: UnsafePointer<pthread_mutexattr_t>?) -> Int32
//给指定的mutex加锁
public func pthread_mutex_lock(_: UnsafeMutablePointer<pthread_mutex_t>) -> Int32
//尝试给指定的mutex加锁，是pthread_mutex_lock的非阻塞版本，返回0则加锁成功，返回其它值以表示当前锁的状态。
public func pthread_mutex_trylock(_: UnsafeMutablePointer<pthread_mutex_t>) -> Int32
//给指定的mutex解锁，必须入pthread_mutex_lock或成功执行的pthread_mutex_trylock成对出现
public func pthread_mutex_unlock(_: UnsafeMutablePointer<pthread_mutex_t>) -> Int32

```
##### 互斥锁的简单使用
```Swift
var mutex = pthread_mutex_t()

//initial mutex
pthread_mutex_init(&mutex, nil)

private func testPthreadMutex() {
    
    pthread_mutex_lock(&mutex)
    
    //your code block in here...
    
    pthread_mutex_unlock(&mutex)
}
```

##### 递归互斥锁的简单使用
```Swift
var rmutex = pthread_mutex_t()

//initial recusive mutex
var attr: pthread_mutexattr_t = pthread_mutexattr_t()
pthread_mutexattr_init(&attr)
pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
pthread_mutex_init(&rmutex, &attr)
pthread_mutexattr_destroy(&attr)

private func testPthreadMutexRecusive() {
    
    pthread_mutex_lock(&rmutex)

    //your code block in here...
    
    pthread_mutex_unlock(&rmutex)
}

```

#### Dispatch_semaphore_t

信号量跟其它的锁概念有所不同，OS上的锁其本质上都是通过Mach内核中的互斥锁`lck_mtx_t`根据不同的不同的场景需求而设计的锁，它们大多采用阻塞的方式，少部分使用忙等的方式；而信号量不一致，它是使用信号的方式来控制多线程对于资源的控制，并且信号量可同时释放信号量以保证多个线程同时访问资源，博主曾经写过[这篇博客](http://www.kobeluo.com/TECH/2017/03/28/dispatch-semaphore/)对信号量的用法做了分析。


简单使用方式大致如下:
```swift

let sema: DispatchSemaphore = DispatchSemaphore.init(value: 1)

private func testSemaphore() {
    
    sema.wait()
	
    // your code block in here...
    
    sema.signal()
}
```
#### NSLock / NSRecusiveLock

`NSLock`是OS封装的一个上层锁对象，它可以用来间接的读取全局数据或者保护一个临界区域的代码安全，`NSLock`支持原子操作。

{% note danger %}

NSLock使用 POSIX线程来实现Lock的行为，当发送一个`unlock()`消息到NSLock对象，你必须确保之前在同样的线程已经发送了一个`lock()`消息,
对于同一个NSLock锁的实例，如果`lock()`和`unlock()`不在同一线程，将引发一个未知的错误（can result in undefined behavior.）。

{% endnote %}

NSLock无法支持对同一个NSLock的实例连续进行两次及以上的`lock()`操作，否则会引发死锁，如果需要递归的调用`lock()`操作，应该是用`NSRecusiveLock`。

`Unlocking a lock that is not locked is considered a programmer error and should be fixed in your code`
如果你尝试解锁一个未被加锁的NSLock对象，这被认为是程序员的错误，同时输出一个类似的错误在console上。

其简单使用如下:
```Swift 

let lock = NSLock.init()
private func testNSLock() {
        
    lock.lock()
    
    // your code block in here...
    
    lock.unlock()
}
    

let rlock = NSRecursiveLock.init()
private func testNSRecusiveLock() {
        
    rlock.lock()

    //your code block in here ...
    
    rlock.unlock()
}
```

#### NSCondition

{% note info %}
官方文档:
A condition object acts as both a lock and a checkpoint in a given thread. The lock protects your code while it tests the condition and performs the task triggered by the condition. The checkpoint behavior requires that the condition be true before the thread proceeds with its task. While the condition is not true, the thread blocks. It remains blocked until another thread signals the condition object.
{% endnote %}

一个Condition对象被用于指定线程的checkpoint或一个锁。 作为锁，可以在当测试某种条件和执行有条件触发的任务时来保护你的代码。作为checkpoint，其要求在线程执行完之前，condition为true,否则该线程将被一直锁住,直到另一个线程发送一个condition对象的信号。

`NSCondition`官方使用六大步：
- lock condition对象(`condition.lock()`)
- 添加一个bool量的判断，用来指示是否需要继续执行下面受保护的内容
- 如果bool量为false,则调用`wait()`或`wait(until:)`函数，用以锁住当前线程，从这个循环返回后继续回到步骤2，继续测试bool量
归纳起来就是 `while (boolvalue == false) { condition.wait() }`
- 如果bool量为true了，则继续向下执行受保护的内容。
- 可选项，更新条件或发送一个condition信号,如果需要的话。(`conditon.signal()` or `condition.broadcast()`)
- 当所有工作完成时，调用 `conditon.unlock()`

简单的锁使用方式如下:
```swift

let condition = NSCondition.init()

private func testNSCondition() {
	
    condition.lock()
    while( booleanvalue == false) {

    	condition.wait()
    }

    //your code in here...

    condition.unlock()    


    //set the booleanvalue to true in a given time.
}

```

作为上层锁，其内部实现复杂度是要高于底层锁的，因此从性能上开率，除特殊需求外，不建议使用此类锁。

最后再上一段官方的使用心得：
{% note info %}
Whenever you use a condition object, the first step is to lock the condition. Locking the condition ensures that your predicate and task code are protected from interference by other threads using the same condition. Once you have completed your task, you can set other predicates or signal other conditions based on the needs of your code. You should always set predicates and signal conditions while holding the condition object’s lock.
{% endnote %}
#### NSConditionLock
使用NSConditionLock对象需要确保线程可以在确定的条件下拿到锁，一旦拿到锁并执行了关键区域的代码(被保护的代码)，该线程可以丢弃该锁或者设置新的相关条件，条件是不固定的，根据你的项目而自定。

其简单使用如下:
```swift
let clock = NSConditionLock.init()

private func testNSConditionLock() {
	
	clock.lock()
    ///your code block in here...
    clock.unlock()

    /// clock.try() 尝试加锁，如果成功获取锁，则返回一个正值，否则返回负值， try()成功，才可以unlock(),否则引发一个未知错误。
}
```


#### @synchronized 

这是Objective-C上面封装的一个上层锁，允许递归使用，其内部处理逻辑相对复杂，因此性能在所有的锁中相对较差，其简单使用方式：

```Swift
@synchronized(lockedObj) {
	
	//code block in here...
}
```
更多关于@synchronized的消息请参考以下链接
https://reddick-wang.github.io/2017/05/12/iOS%E4%B8%AD%E7%9A%84%E9%82%A3%E4%BA%9B%E9%94%81/


相关链接:

OSSpinLock
https://mjtsai.com/blog/2015/12/16/osspinlock-is-unsafe/
https://blog.ibireme.com/2016/01/16/spinlock_is_unsafe_in_ios/

Synchronized
https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Multithreading/ThreadSafety/ThreadSafety.html#//apple_ref/doc/uid/10000057i-CH8-SW3
https://reddick-wang.github.io/2017/05/12/iOS%E4%B8%AD%E7%9A%84%E9%82%A3%E4%BA%9B%E9%94%81/
http://yulingtianxia.com/blog/2015/11/01/More-than-you-want-to-know-about-synchronized/


