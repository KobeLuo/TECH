---
title: GCD系列:信号量(dispatch_semaphore)
date: 2017-03-28 20:44:35
type: "categories"
categories: Objective-C
tags: [GCD, dispatch_semaphore, 信号量]
---
信号量有点像具备N个task并行能力的channel,当channel的并行能力未达到上限时可以任意往里边加task，当达到channel上限时，需要task完成才可以加入新的task.
<!--more-->

### 基础函数

---

{% codeblock lang:objc %}

dispatch_semaphore_t
dispatch_semaphore_create(long value);
dispatch_semaphore_wait(dispatch_semaphore_t sema, dispatch_time_t timeout);
dispatch_semaphore_signal(dispatch_semaphore_t dsema);

{% endcodeblock %}

1.申明一个信号量:dispatch_semaphore_t dsema;
2.创建一个具有n个并行能力的semaphore:dsema = dispatch_semaphore_create(2); 这里创建一个具备2个并行能力的信号量dsema.
3.消耗1个并行能力,例子中当重复调用2次此函数，代码将造成阻塞,阻塞的时间是timeout，实际开发中，可以创建一dispatch_time_t实例，也可使用DISPATCH_TIME_FOREVER,将永远等待知道发送一个signal为止.因此,如果不能确定一定会发送signal，慎用DISPATCH_TIME_FOREVER.
4.发送1个signal.

### 主要用途

---

1. 当前线程执行代码等待其它线程代码执行结束   
2. 控制异步task并发数量


- 实例1: 当前Thread同步执行等待其他Thread返回结果：

{% codeblock lang:objc %}

void normalizedSemaphore() {

	NSLog(@"current thread begin...");
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);

	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

		for(NSUInteger index = 0 ; index < 3 ; index ++) {

			NSLog(@"other thread message:%lu",index);

			if (index == 2) {

			dispatch_semaphore_signal(semaphore);
		}
	}
});

dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

	NSLog(@"current thread continue...");

	dispatch_semaphore_signal(semaphore);
}

{% endcodeblock %}

代码中，创建了一个同时允许并发为1的semaphore,当执行到current thread continue...这条log时,执行被卡住了，等待异步代码块调用dispatch_semaphore_signal(semaphore)继续往下执行.
输出结果:

{% codeblock lang:objc %}

2017-02-27 00:26:11.392620 Semaphore[61812:11351508] current thread begin...
2017-02-27 00:26:11.392751 Semaphore[61812:11351539] other thread message:0
2017-02-27 00:26:11.392772 Semaphore[61812:11351539] other thread message:1
2017-02-27 00:26:11.392784 Semaphore[61812:11351539] other thread message:2
2017-02-27 00:26:11.392848 Semaphore[61812:11351508] current thread continue...

{% endcodeblock %}

- 实例2：控制异步并发数量

{% codeblock lang:objc %}
-(void)managerAsynTaskDemo {

	NSMutableArray *tasks = [NSMutableArray new];

	for (NSUInteger index = 0 ; index < 10; index ++) {

		[tasks addObject:@(index)];
	}

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

		[tasks enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {

			[self logTaskIndex:[obj unsignedIntegerValue]];
		}];
	});
}

dispatch_semaphore_t _dsema;
void (^logTaskIndexHandle)(NSUInteger) = ^(NSUInteger index) {

	NSLog(@"task index:%lu",index);
};
-(void)logTaskIndex:(NSUInteger)index {

	if (!_dsema) _dsema = dispatch_semaphore_create(5);

	dispatch_semaphore_wait(_dsema, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC));
	logTaskIndexHandle(index);
	dispatch_semaphore_wait(_dsema, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC));
	dispatch_semaphore_signal(_dsema);
}
{% endcodeblock %}

这个例子中，我们产生了10个异步的task,创建了一个并发量为5的信号量dsema,并且在很短的时间内都异步调用logTaskIndex方法,

{% codeblock lang:objc %}
2017-02-27 00:28:01.579778 Semaphore[61846:11355856] task index:0
2017-02-27 00:28:01.579822 Semaphore[61846:11355856] task index:1
2017-02-27 00:28:01.579838 Semaphore[61846:11355856] task index:2
2017-02-27 00:28:01.579850 Semaphore[61846:11355856] task index:3
2017-02-27 00:28:01.579862 Semaphore[61846:11355856] task index:4
2017-02-27 00:28:02.580413 Semaphore[61846:11355856] task index:5
2017-02-27 00:28:03.585241 Semaphore[61846:11355856] task index:6
2017-02-27 00:28:04.589975 Semaphore[61846:11355856] task index:7
2017-02-27 00:28:05.592348 Semaphore[61846:11355856] task index:8
2017-02-27 00:28:06.596368 Semaphore[61846:11355856] task index:9
{% endcodeblock %}

通过日志看到,前5个任务完成时间间隔非常短，从index=5的task开始每隔1秒钟执行一个task。是因为，打印日志的时候，并没有调用dispatch_semaphore_signal(semaphore);函数，所以只能等待超时时间1秒.
如果这里的超时时间设置成了DISPATCH_TIME_FOREVER，请思考一下，最终的打印结果是什么呢？

---

**推荐一个封装的semaphore函数:**

{% codeblock lang:objc %}
void dispatch_semaphore_async_handle(dispatch_semaphore_t dsema,dispatch_time_t timeout, void (^block)(dispatch_semaphore_t dsema)) {

	dsema = dsema ?: dispatch_semaphore_create(0);
	timeout = timeout ?: DISPATCH_TIME_FOREVER;
	dispatch_semaphore_wait(dsema, timeout);
	block(dsema);
	dispatch_semaphore_wait(dsema, timeout);
	dispatch_semaphore_signal(dsema);
}
{% endcodeblock %}

**使用方法如下:**

{% codeblock lang:objc %}
dispatch_semaphore_async_handle(nil, 0, ^(dispatch_semaphore_t dsema){

	//        some code...
	dispatch_semaphore_signal(dsema);
});
{% endcodeblock %}


{% note info %} 
- 推荐一篇不错的GCD文章  http://www.cocoachina.com/ios/20160225/15422.html
{% endnote %}
