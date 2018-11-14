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

本次测试博主尝试了Repeat不同的次数下，各类锁的耗时情况，发现各类锁的耗时大小顺序并不是固定的，并且差异挺大，仅仅只有单线程且去掉上下文的情况下，测试结果相对稳定，博主猜测大概是因为测试时电脑瞬时性能、CPU使用情况和内核调度的情况有关系，具体原因不敢妄下结论。

**因此，测试结果只能从某个方面反映出锁的效率，也许它并不是最准确的结果，它是在特定环境下的真实测试结果。**

去掉上下文的测试结果，仅仅只能说明锁本身的实现复杂度和内部的执行效率,它并不能说明锁在实际使用过程中，结合上下文的执行效率，只能作为理论依据。

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

##### 多线程，去掉上下文

![测试元数据](multiAndContextResign.png)
![测试图表](contextResgnMulti.png)



##### 多线程，保留上下文

![测试元数据](multiAndContextKeep.png)
![测试图表](contextKeepMulti.png)


