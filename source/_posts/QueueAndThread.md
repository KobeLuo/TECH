---
title: OC中的多线程理解
type: categories
comments: true
date: 2017-04-14 18:35:33
categories: Objective-C
tags: [线程，队列，同步，异步，串行，并行，多线程]
---

{% cq %}
这段时间面试较多，
发现很多Developer对多线程中的基本概念很模糊，
为了帮助到大家理解，这篇文章系统的阐述了
**线程和队列？
同步和异步？
串行与并行？**
他们是怎么产生的，在执行过程中，扮演什么样的角色。
{% endcq %}
<!--more-->

我们先分析一下他们各自的定义。。。

<span class="greenTitle">线程(Thread)</span>
**线程:**是操作系统能够进行运算调度的最小单位，是独立调度和分派的基本单位，它被包含在进程中，是进程的实际运作单位，是一个进程中一个单一顺序的控制流，blablabla...关于线程更多的解释，请右转[线程-维基百科](https://zh.wikipedia.org/wiki/%E7%BA%BF%E7%A8%8B)。
<span class="conclusion">从定义中可以知道，所有执行的单元都是在线程中执行的。</span> 

在iOS中，创建线程的方式有三种:pthread,NSThread,NSOperation和GCD(Grand Central Dispatch)，
pthread是Linux提供的线程使用库，C语法，需要手动创建，手动管理内存，相对比较复杂，开发过程中一般的需求不会使用到pthread；
关于如何使用这些方式，怎么取舍，网上的博客有很多很好的说明，这里不再赘述。

开发过程中,你可能会使用以下方法来获取线程:
{% codeblock lang:objc %}
[NSThread currentThread]; 
//获取当前执行代码块所在的线程.
[NSThread mainThread];
//获取主线程.
{% endcodeblock %}


<span class="greenTitle">队列(Thread)</span>
**队列:**先进先出（FIFO)——先进队列的元素先出队列，队列的数据结构分析请右转[队列定义](http://blog.csdn.net/leichelle/article/details/7546775)。
iOS中的队列由两种形式：串行队列和并行队列，其实都是FIFO先进先出的队列，<span class="conclusion">串行队列是指队列中的下一个任务必须要等待上一个任务执行完成才能继续调度，而并行队列则无需等待上一个任务完成即可发起下一个任务的调度</span>，后面会有详细分析。

开发过程中，你可能会使用到一下方式来获取队列:
{% codeblock lang:objc %}
dispatch_get_main_queue()
//获取主队列,该队列由系统派发，后面会继续详解。
dispatch_get_global_queue(long identifier, unsigned long flags)
//获取全局队列
dispatch_queue_create(const char *_Nullable label,dispatch_queue_attr_t _Nullable attr);
//创建一个队列，label用来指定队列的特定标识，attr用来指定队列调度的方式是串行还是并行。
{% endcodeblock %}


- dispatch_get_main_queue() 用来获取主队列，该队列非常特殊,它直接是关联到主线程上面的，[查看解释](#user-content-mainQueue),<span class="conclusion">也就是说，所有的任务加到该队列上都会自动在主线程中执行</span>,关于这一点，我们会在下面举例说明，你可以使用三种方法`dispatch_main`,` UIApplicationMain (iOS) or NSApplicationMain (macOS)`或` CFRunLoopRef`来调用提交到主线程的任务;由于是系统派发管理的队列，在该队列上使用 `dispatch_suspend`, `dispatch_resume`, `dispatch_set_context`无效。

- dispatch_get_global_queue(long identifier, unsigned long flags) 跟main queue一样，该队列由系统派发因此无法使用GCD修改该队列，identifier推荐使用QOS方式指定，细看请右转[【GCD系列:Dispatch_queue】](http://www.kobeluo.com/TECH/2017/03/20/dispatch_queue/)

- dispatch_queue_create(const char *_Nullable label,dispatch_queue_attr_t _Nullable attr); 请右转[【GCD系列:Dispatch_queue】](http://www.kobeluo.com/TECH/2017/03/20/dispatch_queue/)。


<span class="greenTitle">串行、并行</span>
是指队列中多个任务的执行方式，串行(FIFO)即队列中后面的任务必须要等到前一个任务执行结束才可继续执行，
并行任务其实质也是也是串行执行的，只是由于执行速度非常快，我们就认为队列中的任务是同时执行的，其实他们也是有先后顺序的。


<span class="greenTitle">同步、异步</span>
这里一定要明白一个概念，<span class="conclusion">同步异步是相对于某一个特定的线程来讨论的</span> 
举个例子: 下面这段代码在mainThread中执行的，
{% codeblock lang:objc %}
envir:mainThread begin

dispatch_sync(customQueue, ^{statement1..});
dispatch_async(customQueue, ^{statement2...});

envir:mainThread end
{% endcodeblock %}
`dispatch_sync(customQueue, ^{statement1..});`这是指:代码块`statement1`是同步执行的，由于当前线程是mainThread，所以代码块`statement1`也是在mainThread中执行的，至于代码块`statement1`是否造成线程死锁这取决于customQueue的实现和内部逻辑，这里不做细究。
`dispatch_async(customQueue, ^{statement2...});`这是指:代码块`statement2`是异步执行的，dispatch_async会自动为代码块`statement2`分配一个新的线程去执行，那`statement2`其实就脱离了主线程，到另一个线程去执行了。


{% note danger %} 

<span class="conclusion">以上内容简单分析了多线程使用过程中所涉及到的基础知识，而概念多是抽象的，后面会举一些例子来继续深化概念。</span> 


{% endnote%}

---

<span class="codeDemo">1:串行队列任务调度</span>
串行队列中的任务之间有依赖关系，后面的任务必须要依赖前面任务的完成后才会被队列调度，看代码:

{% codeblock lang:objc %}
+ (void)testSerialQueue {

	dispatch_queue_t queue = dispatch_queue_create("queue.demo", DISPATCH_QUEUE_SERIAL);

	__block NSUInteger index = 0;

	for (NSInteger count = 0 ; count < 5; count ++) {
		//note1.
		dispatch_sync(queue, ^{
			//codeBlock
			NSLog(@"Thread:%@,index:%lu",[NSThread currentThread],index ++);
			sleep(1);
		});
	}
}
{% endcodeblock %}
**代码解释:**
- 使用`dispatch_queue_create`创建一个队列，不做更多解释，详情请参考另一篇博客[Dispatch_queue类详解](http://www.kobeluo.com/TECH/2017/03/20/dispatch_queue/#more)
- 使用for循环来重复执行五次代码块.
- `dispatch_sync(queue,codeblock)`这个函数的作用,官方的文档是:`Submits a block for synchronous execution on a dispatch queue.`在一个队列上提交一个用于同步执行的代码块,所以，该函数的意义就是将codeBlock提交到queue上，当codeBlock被调度时，采用同步的方式执行codeBlock。

最终的结果不难理解，大约每个一秒钟打印一条日志:
{% codeblock lang:objc %}
2017-04-16 00:30:00.675 Blog_Demo[9913:4446408] Thread:<NSThread: 0x600000062cc0>{number = 1, name = main},index:0
2017-04-16 00:30:01.747 Blog_Demo[9913:4446408] Thread:<NSThread: 0x600000062cc0>{number = 1, name = main},index:1
2017-04-16 00:30:02.820 Blog_Demo[9913:4446408] Thread:<NSThread: 0x600000062cc0>{number = 1, name = main},index:2
2017-04-16 00:30:03.895 Blog_Demo[9913:4446408] Thread:<NSThread: 0x600000062cc0>{number = 1, name = main},index:3
2017-04-16 00:30:04.970 Blog_Demo[9913:4446408] Thread:<NSThread: 0x600000062cc0>{number = 1, name = main},index:4
{% endcodeblock %}

**Q:** note1处将dispatch_sync更换成dispatch_async,执行的结果会是怎样的呢？？？？？
**A:** 改成async后，代码的意义就是，在queue上提交一个异步执行的代码块`codeBlock`，那么循环五次，系统可能会派发不同与当前线程的线程去执行代码块`codeBlock`,那系统会派发几个线程去执行五次循环代码呢？？？？答案是1个线程，**因为代码块`codeBlock`是内部是同步执行的，而queue是串行队列，当queue调度第一个循环任务执行时，由于内部是串行执行的，所以当第二个循环任务执行时，第一个循环任务已经执行结束，因此，系统会继续使用之前派发给第一个循环任务的的线程来执行第二次循环**，以此类推！！！有兴趣的同学可以敲一下，这里提供源码:
{% codeblock lang:objc %}
+ (void)testSerialQueue {

dispatch_queue_t queue = dispatch_queue_create("queue.demo", DISPATCH_QUEUE_SERIAL);

	__block NSUInteger index = 0;

	for (NSInteger count = 0 ; count < 5; count ++) {
		//note1.
		dispatch_async(queue, ^{
			//codeBlock
			NSLog(@"Thread:%@,index:%lu",[NSThread currentThread],index ++);
			sleep(1);
		});
	}
}
{% endcodeblock %}

<span class="conclusion">那最终的结果还是顺序执行，但是执行代码块的线程不再是当前线程</span>

<hr>

<span class="codeDemo">2:并行队列任务调度</span>
并行队列任务调度是指同一队列中的任务时并行执行的，代码如下:
{% codeblock lang:objc %}
+ (void)testConcurrentQueue {

	dispatch_queue_t queue = dispatch_queue_create("queue.demo", DISPATCH_QUEUE_CONCURRENT);
	__block NSUInteger index = 0;
	for (NSInteger count = 0 ; count < 5; count ++) {
		//note1
		dispatch_async(queue, ^{
			//codeBlock
			sleep(1);
			NSLog(@"Thread:%@,index:%lu",[NSThread currentThread],index ++);
		});
	}

	NSLog(@"function end...");
}
{% endcodeblock %}
**代码解释:**
- 第一句`dispatch_queue_create`,通过参数控制，创建一个并行队列。
- 使用for循环来执行五次代码块。
- `dispatch_async(queue,codeblock)`,这个函数的作用是提交一个用于异步执行的代码块到队列queue上，由于是异步执行代码块`codeBlock`，而queue又是并行队列，所以，任务与任务之间没有依赖关系，系统会派发多个线程来处理queue中的五个代码块，执行结果如下:
{% codeblock lang:objc %}
2017-04-19 17:32:23.621 Dispatch[59857:1236810] function end...
2017-04-19 17:32:24.694 Dispatch[59857:1236922] Thread:<NSThread: 0x60000006d0c0>{number = 3, name = (null)},index:0
2017-04-19 17:32:24.694 Dispatch[59857:1236942] Thread:<NSThread: 0x608000072280>{number = 7, name = (null)},index:4
2017-04-19 17:32:24.694 Dispatch[59857:1236933] Thread:<NSThread: 0x608000073000>{number = 4, name = (null)},index:1
2017-04-19 17:32:24.694 Dispatch[59857:1236920] Thread:<NSThread: 0x60000007a0c0>{number = 6, name = (null)},index:3
2017-04-19 17:32:24.694 Dispatch[59857:1236919] Thread:<NSThread: 0x6080000759c0>{number = 5, name = (null)},index:2
{% endcodeblock %}
从log打印日期可以看出，for循环中的5个代码块几乎是同时执行的。
<br>
**Q:** 如果将代码中note1的位置dispatch_async改成dispatch_sync,执行的结果会是怎么样的？？？？？
**A:** 如果该dispatch_sync，意味着五个代码块`codeBlock`将在当前线程中同步执行，由于同一线程同一时间最多只能执行一块代码，那么执行到for循环内部时，整个函数就将停止下来，等待加入到queue中的block执行完成后才能继续向下执行，源代码如下:

{% codeblock lang:objc %}
+ (void)testConcurrentQueue {

	dispatch_queue_t queue = dispatch_queue_create("queue.demo", DISPATCH_QUEUE_CONCURRENT);
	__block NSUInteger index = 0;
	for (NSInteger count = 0 ; count < 5; count ++) {
		dispatch_sync(queue, ^{
			//codeBlock
			sleep(1);
			NSLog(@"Thread:%@,index:%lu",[NSThread currentThread],index ++);
		});
	}

	NSLog(@"function end...");
}
{% endcodeblock %}

<span class="conclusion">尽管Queue是一个并行队列，但因为在同一线程执行循环，代码最终将串行执行下去</span>
<hr>


<span class="codeDemo" id="user-content-mainQueue">2:为什么调用dispatch_get_main_queue()可以回到主线程</span>
地球人都知道，使用函数`dispatch_async(dispatch_get_main_queue(), ^{codeBlock});`可以回到主线程，
分析代码我们发现这句代码的意思是:将脱离于当前线程（去另一个`线程T`）执行的codeBlock加入到主队列(mainQueue)中，
那么问题来了，为什么`线程T`就一定指向了主线程呢？官方文档:`Returns the serial dispatch queue associated with the application’s main thread `
字面意思：mainQueue是创建系统创建的自动关联到主线程的队列，具体到执行就是所有加入到mainqueue中的代码块，无论在什么线程，都将切换到主线程执行，
这样就不难理解为什么所有加入到mainqueue的任务一定指向主线程，代码如下:
{% codeblock lang:objc %}
+ (void)testMainqueueAndMainThread {

	//让下面的代码块脱离主线程，并由全局并发队列调度
	dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{

		NSLog(@"log1 > current thread:%@",[NSThread currentThread]);

		dispatch_sync(dispatch_get_main_queue(), ^{
	
			NSLog(@"log2 > current thread:%@",[NSThread currentThread]);
		});
	});
}
{% endcodeblock %}
**代码解释:**
- 第一句让整个内部的代码脱离主线程，进入异步线程执行，并在全局队列中调度。
- log1 打印了内部代码实际执行的线程。
- 使用`dispatch_sync(dispatch_get_main_queue(), ^{codeBlock});`让代码块`codeBlock`在当前线程同步执行，并加入到主队列中，理论情况下，log2 打印的线程应该与 log1打印一致，但是由于mainqueue的特殊性，执行结果如下:

{% codeblock lang:objc %}
2017-04-19 17:44:47.131 Dispatch[60261:1244756] log1 > current thread:<NSThread: 0x608000269a40>{number = 3, name = (null)}
2017-04-19 17:44:47.145 Dispatch[60261:1244496] log2 > current thread:<NSThread: 0x60000007f3c0>{number = 1, name = main}
{% endcodeblock %}
<span class="conclusion">任何加入到main queue中的任务都将调度至主线程执行。</span>
<hr>
<span class="codeDemo">3:线程死锁到底是怎样造成的</span>

<span class="conclusion">造成线程死锁的方式只有一种，那就是让任务之间相互等待，两个任务都永远无法完成</span>

下面我们来分析一种典型的线程死锁方式，上代码:
{% codeblock lang:objc %}
+ (void)classicDeadlock {

	NSLog(@"currentThread:%@",[NSThread currentThread]);//task 1
	//doingTask begin
	dispatch_sync(dispatch_get_main_queue(), ^{

		NSLog(@"dead lock ....");//task 2
	});
	//doingTask end

	NSLog(@"classic method test end!");// task3
}

调用方式如下://invoke deadlock method
dispatch_async(dispatch_get_main_queue(), ^{

	[[self class] classicDeadlock]; //task 0
});
{% endcodeblock %}
**代码解释:**
- classicDeadlock中task1处打印了当前线程，然后将 在当前线程执行的task2加入到mainqueue中，最后是task3。
- 调用方式，使用mainqueue的特性将类方法调度至主线程执行,[查看理解](#user-content-mainQueue);。

**执行结果:**
这段代码执行完成task1之后就将陷入死锁，那么造成死锁的原因到底是什么？这篇文章上面的基础概念应该可以给你满意的答案。
来来来，我们一步一步的分析这段代码:
{% codeblock lang:objc %}
1.假设mainQueue当前是空闲状态，如下:
mainQueue:____________________

2.调用函数(invoke deadlock method),调用此函数时,将task0加入到mainQueue中，mainQueue如下:
mainQueue:__task0__________________

3.执行task0，task0的执行图如下:
task0(mainThread)  
	- task1
	- task2 ，task2是同步执行的，因此task3需要等待task2执行结束。
	- task3

- 执行task1,
- 紧接着就是将同步执行task2加入到mainQueue中,此时mainQueue任务列表如下:
mainQueue:__task0__task2______________

由于mainQueue是系统派发的串行队列，！！！！所以task2需要等待task0执行结束，
而此时task0执行到doingTask处，task2是同步加入到mainqueue中的，因此，！！！！task0又必须等待task2执行结束。
这样:task2和task0其实就形成了相互等待，永远也不可能完成，即造成了主线程死锁。
{% endcodeblock %}

{% note info %}
<span id="user-content-deadlock">通过以上分析可以发现,造成线程死锁的条件就是:</span>
<span class="conclusion">代码块A由串行队列调度并在指定线程执行,代码块A中包含了一个代码块B，其属性是加入到代码块A所在的队列中去同步执行代码块B</span>
{% endnote %}


<br>

<span class="conclusion">假设我们将`//doingTask`处改成dispatch_async，还会造成死锁吗？ 由于mainqueue的特殊性[查看理解](#user-content-mainQueue);答案是:肯定的。</span>

<hr>

**现在我们把问题引申到多线程中的任意线程:**，顺便复习一下线程死锁的条件，来看一下代码：
{% codeblock lang:objc %}

+ (void)testThreadDeadlockQithQueue:(dispatch_queue_t)queue {

	NSLog(@"currentThread:%@",[NSThread currentThread]);//task 5
	//codeBlock 2 begin
	dispatch_sync(queue, ^{

		NSLog(@"dead lock ....");//task 6
	});
	//codeBlock 2 end
	NSLog(@"classic method test end!");// task7
}

调用处这样写：
dispatch_queue_t serialQueue = dispatch_queue_create("serial.queque.demo", DISPATCH_QUEUE_SERIAL);
dispatch_async(serialQueue, ^{

	[[self class] testThreadDeadlockQithQueue:serialQueue]; //task 4
});

{% endcodeblock %}

按照上面描述的[死锁条件](#user-content-deadlock)，在类方法`testThreadDeadlockQithQueue:`调用处，
1.创建一个serialQueue串行队列,
2.在某个指定线程(ThreadA)中执行类方法`testThreadDeadlockQithQueue:`,代码块task4.
3.在代码块task4中包含了一个代码块`codeBlock 2`,其属性是，在当前线程同步执行，并加入到当前线程所在的同步队列`serialQueue`中，
4.即造成ThreadA线程死锁！！！。有兴趣的朋友可以复制代码撸一把。
<br>
<span class="conclusion">假设我们将`//codeBlock 2`处改成dispatch_async，还会造成死锁吗？答案是: 否定的。</span>
由于//doingTask是异步执行的，所以实际上task0执行的代码变成了：
**threadA**
	task1
	task3

**threadB**
	task2
当mainThread执行到`//codeBlock 2`时，task2就将跳转至另外一个线程去执行，此时task0将不再等待task2的执行结束，那就不能构成死锁的条件了，由于task2依然需要等待task0执行结束，

---

{% note info %}
由于博主各种杂事阐释，导致这篇博客前后经历了一周才完成，
行文不当之处，也欢迎大家留言指正，小可在此感谢大家。
{% endnote %}

