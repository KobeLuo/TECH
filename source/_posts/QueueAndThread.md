---
title: OC中的多线程理解
type: categories
comments: true
date: 2017-04-14 18:35:33
categories: OC
tags: [线程，队列，同步，异步，串行，并行，多线程]
---

{% cq %}
这篇博客，系统的讲解，
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

--- 

<span class="greenTitle">队列(Thread)</span>
**队列:**先进先出（FIFO)——先进队列的元素先出队列，队列的数据结构分析请右转[队列定义](http://blog.csdn.net/leichelle/article/details/7546775)。
iOS中的队列由两种形式：串行队列和并行队列，其实都是FIFO先进先出的队列，串行队列是指队列中的下一个任务必须要等待上一个任务执行完成才能
继续调度，而并行队列则无需等待上一个任务完成即可发起下一个任务的调度。
下面这个例子用于说明串行队列任务调度:
{% codeblock lang:objc %}
+ (void)testSerialQueue {

	dispatch_queue_t queue = dispatch_queue_create("queue.demo", DISPATCH_QUEUE_SERIAL);

	__block NSUInteger index = 0;

	for (NSInteger count = 0 ; count < 5; count ++) {

		dispatch_sync(queue, ^{
			//codeBlock
			NSLog(@"Thread:%@,index:%lu",[NSThread currentThread],index ++);
			sleep(1);
		});
	}
}
{% endcodeblock %}
这里对改代码块进行逐个讲解：
- 使用`dispatch_queue_create`创建一个队列，不做更多解释，详情请参考另一篇博客[Dispatch_queue类详解](http://www.kobeluo.com/TECH/2017/03/20/dispatch_queue/#more)
- 使用for循环来重复执行五次代码块.
- `dispatch_sync(queue,codeblock)`这个函数的作用,官方的文档是:`Submits a block for synchronous execution on a dispatch queue.`在一个队列上提交一个用于同步执行的代码块,所以，该函数的意义就是将codeBlock提交到queue上，当codeBlock被调度时，采用同步的方式执行codeBlock。
最终的结果不难理解，大约每个一分钟打印一条日志:
{% codeblock lang:objc %}
2017-04-16 00:30:00.675 Blog_Demo[9913:4446408] Thread:<NSThread: 0x600000062cc0>{number = 1, name = main},index:0
2017-04-16 00:30:01.747 Blog_Demo[9913:4446408] Thread:<NSThread: 0x600000062cc0>{number = 1, name = main},index:1
2017-04-16 00:30:02.820 Blog_Demo[9913:4446408] Thread:<NSThread: 0x600000062cc0>{number = 1, name = main},index:2
2017-04-16 00:30:03.895 Blog_Demo[9913:4446408] Thread:<NSThread: 0x600000062cc0>{number = 1, name = main},index:3
2017-04-16 00:30:04.970 Blog_Demo[9913:4446408] Thread:<NSThread: 0x600000062cc0>{number = 1, name = main},index:4
{% endcodeblock %}

下面这个例子用于说明并行队列的任务调度:

。。。。。
未完待续。
