---
title: GCD系列:队列(dispatch_queue)
date: 2017-03-20 11:44:22
type: "categories"
categories: Mac Develop
tags: [GCD,Dispatch queue,队列]
---

<blockquote class="blockquote-center">GCD是基于C封装的函数,具备非常高的效率,
在ARC环境下,无须主动管理内存,
无须dispatch_retain和dispatch_release,
可以将重点关注在业务逻辑上。
GCD是基于队列的封装，**下面浅要解析GCD的队列**。
</blockquote>
<!--more-->

### GCD获取线程的方式

---

下面是Apple官方提供的获取线程相关函数

{% codeblock lang:objc %}
- void dispatch_sync(dispatch_queue_t queue, dispatch_block_t block);
//获取一个异步线程队列，queue用于指定block执行体所在的队列
- void dispatch_sync_f(dispatch_queue_t queue,void *_Nullable contex,dispatch_function_t work); 
//跟dispatch_sync类似，只不过接收的是一个dispatch_function_t的函数。
- void dispatch_async(dispatch_queue_t queue, dispatch_block_t block); 
//获取一个异步线程，接收一个闭包block.
- void dispatch_async_f(dispatch_queue_t queue,void *_Nullable context,dispatch_function_t work);
//获取一个异步线程,接收一个函数指针.
{% endcodeblock %}

### GCD获取队列的方式
---

{% codeblock lang:objc %}
-  dispatch_queue_t dispatch_get_main_queue(); 
//获取主队列
- dispatch_queue_t dispatch_get_global_queue(long identifier, unsigned long flags); 
//获取全局队列,由系统分配,分配完成后不可更改,flags是预留字段，传递任何非0值将返回一个NULL值引发异常，identifier指定全局队列的级别，队列的级别如下:

#define DISPATCH_QUEUE_PRIORITY_HIGH 2
#define DISPATCH_QUEUE_PRIORITY_DEFAULT 0
#define DISPATCH_QUEUE_PRIORITY_LOW (-2)
#define DISPATCH_QUEUE_PRIORITY_BACKGROUND INT16_MIN
{% endcodeblock %}

- 推荐使用基于QOS_CLASS的属性级别.

{% codeblock lang:objc %}
QOS_CLASS_USER_INTERACTIVE  
//最高优先级,用于UI更新等与用户交互的操作.
QOS_CLASS_USER_INITIATED        
//初始化优先级，用于初始化等，等同于DISPATCH_QUEUE_PRIORITY_HIGH
QOS_CLASS_DEFAULT                   
//默认优先级，等同于DISPATCH_QUEUE_PRIORITY_DEFAULT
QOS_CLASS_UTILITY                     
//低优先级，等同于DISPATCH_QUEUE_PRIORITY_LOW
QOS_CLASS_BACKGROUND         
//后台级,用户用户无法感知的一些数据处理，等同于DISPATCH_QUEUE_PRIORITY_BACKGROUND
{% endcodeblock %}

- 自己创建的队列

GCD中使用`dispatch_queue_t dispatch_queue_create(const char *_Nullable label,dispatch_queue_attr_t _Nullable attr);`来创建一个队列，其中label表示该队列的唯一标识字符串，使用`const char *dispatch_queue_get_label(dispatch_queue_t _Nullable queue);`来获取该字符串,参数attr指定队列的执行顺序，有以下参数:

{% codeblock lang:objc %}
DISPATCH_QUEUE_SERIAL        
//指定串行（FIFO）队列,等同于传入参数NULL
DISPATCH_QUEUE_CONCURRENT    
//指定并发队列,
dispatch_queue_attr_t dispatch_queue_attr_make_with_qos_class(dispatch_queue_attr_t _Nullable attr,dispatch_qos_class_t qos_class, int relative_priority);
//产生一个基于QOS_CLASS的队列.
{% endcodeblock %}

#### dispatch_apply应用

---

dispatch_apply必须要结合dispatch_async 或者dispatch_async_f函数一起使用,如果脱离了dispatch_async函数,程序很容易crash，需要特别关注.
在指定的queue中去直接执行dispatch_apply(count,queue,block);会直接引发crash!

{% codeblock lang:objc %}
- void dispatch_apply(size_t iterations, dispatch_queue_t queue,DISPATCH_NOESCAPE void (^block)(size_t));
{% endcodeblock %}

应用一个block,循环执行block代码块的次数是iterations次，每次执行的index通过size_t参数传递到block代码块内部
*queue*:指定apply函数接收的闭包block执行对应的队列方式,如果是串行队列,跟for循环功能一致，无法达到优化性能的目的。
如果是并行队列,则重复执行block的顺序不定,以达到优化性能的目的，下面是2个简单的例子:

#### case 1:
{% codeblock lang:objc %}
void dispatchApply() {

dispatch_queue_t queue = dispatch_get_global_queue(0, 0);

dispatch_async(dispatch_get_main_queue(), ^{

	//执行的顺序取决于queue是串行还是并行，如果使用串行就跟for循环一样,没有意义
	//Dispatch_apply函数主要的功能是提高性能.
	dispatch_apply(10, queue, ^(size_t index) {

		NSLog(@"index....%lu",index);
	});
	//dispatch_apply是串行执行，直到10次invoke complete的时候，才继续往下执行.
	NSLog(@"ddddd");
	});
}
{% endcodeblock %}
输出结果:  **可以看出，是并行执行的，达到了apply优化性能的目的.**
{% codeblock lang:objc %}
2017-02-27 14:56:03.856182 dispatch_queue[3154:130315] index....0
2017-02-27 14:56:03.856182 dispatch_queue[3154:130336] index....2
2017-02-27 14:56:03.856205 dispatch_queue[3154:130337] index....1
2017-02-27 14:56:03.856240 dispatch_queue[3154:130315] index....4
2017-02-27 14:56:03.856251 dispatch_queue[3154:130336] index....5
2017-02-27 14:56:03.856208 dispatch_queue[3154:130335] index....3
2017-02-27 14:56:03.856272 dispatch_queue[3154:130315] index....6
2017-02-27 14:56:03.856278 dispatch_queue[3154:130336] index....8
2017-02-27 14:56:03.856280 dispatch_queue[3154:130337] index....7
2017-02-27 14:56:03.856293 dispatch_queue[3154:130335] index....9
2017-02-27 14:56:03.856327 dispatch_queue[3154:130315] ddddd
{% endcodeblock %}

#### case 2:

{% codeblock lang:objc %}
void dispatchApplySerial() {

	dispatch_queue_t queue = dispatch_get_main_queue();

	dispatch_async(dispatch_get_global_queue(0, 0), ^{

		//执行的顺序取决于queue是串行还是并行，如果使用串行就跟for循环一样,没有意义
		//Dispatch_apply函数主要的功能是提高性能.
		dispatch_apply(10, queue, ^(size_t index) {

			NSLog(@"index....%lu",index);
		});
		//dispatch_apply是串行执行，知道10次invoke complete的时候，才继续往下执行.
		NSLog(@"ddddd");
	});
}

输出结果:
2017-02-27 14:53:40.472788 dispatch_queue[3096:128184] index....0
2017-02-27 14:53:40.472830 dispatch_queue[3096:128184] index....1
2017-02-27 14:53:40.472842 dispatch_queue[3096:128184] index....2
2017-02-27 14:53:40.472851 dispatch_queue[3096:128184] index....3
2017-02-27 14:53:40.472860 dispatch_queue[3096:128184] index....4
2017-02-27 14:53:40.472868 dispatch_queue[3096:128184] index....5
2017-02-27 14:53:40.472877 dispatch_queue[3096:128184] index....6
2017-02-27 14:53:40.472885 dispatch_queue[3096:128184] index....7
2017-02-27 14:53:40.472893 dispatch_queue[3096:128184] index....8
2017-02-27 14:53:40.472902 dispatch_queue[3096:128184] index....9
2017-02-27 14:53:40.472931 dispatch_queue[3096:128223] ddddddddd
{% endcodeblock %}

{% codeblock lang:objc %}
- void dispatch_apply_f(size_t iterations, dispatch_queue_t queue,void *_Nullable context,void (*work)(void *_Nullable, size_t));
{% endcodeblock %}
跟dispatch_apply功能一致,方法接收一个函数指针.

### void dispatch_set_target_queue(dispatch_object_t object,dispatch_queue_t _Nullable queue);

---

dispatch_set_target_queue可以将object指向的dispatch_object_t对象的队列方式按照参数2的queue的队列方式去执行，它的一大功能就是可以把并发的函数变为串行执行,下面是例子:
{% codeblock lang:objc %}
void setTargetQueue() {

	dispatch_queue_t _serialQueue = dispatch_queue_create("this.is.serial.queue", DISPATCH_QUEUE_SERIAL);
	dispatch_queue_t _concurrcyQueue = dispatch_queue_create("this.is.concurrency.queue", DISPATCH_QUEUE_CONCURRENT);
	//	dispatch_set_target_queue(_concurrcyQueue,_serialQueue);
	NSInteger index = 0;
	while (index ++ < 5) {

		dispatch_async(_concurrcyQueue, ^{ NSLog(@"11111111111"); });
		dispatch_async(_concurrcyQueue, ^{ NSLog(@"22222222222"); });
		dispatch_async(_serialQueue, ^{	NSLog(@"3333333333"); });
	}
}
//执行的结果如下：
2017-02-27 15:22:42.853347 dispatch_queue[3443:148056] 3333333333
2017-02-27 15:22:42.853346 dispatch_queue[3443:148077] 11111111111
2017-02-27 15:22:42.853367 dispatch_queue[3443:148069] 11111111111
2017-02-27 15:22:42.853375 dispatch_queue[3443:148057] 22222222222
2017-02-27 15:22:42.853437 dispatch_queue[3443:148056] 3333333333
2017-02-27 15:22:42.853475 dispatch_queue[3443:148077] 22222222222
2017-02-27 15:22:42.853482 dispatch_queue[3443:148069] 11111111111
2017-02-27 15:22:42.853499 dispatch_queue[3443:148057] 22222222222
2017-02-27 15:22:42.853507 dispatch_queue[3443:148056] 3333333333
2017-02-27 15:22:42.853519 dispatch_queue[3443:148077] 11111111111
2017-02-27 15:22:42.853529 dispatch_queue[3443:148069] 22222222222
2017-02-27 15:22:42.853538 dispatch_queue[3443:148057] 11111111111
2017-02-27 15:22:42.853546 dispatch_queue[3443:148056] 3333333333
2017-02-27 15:22:42.853557 dispatch_queue[3443:148077] 22222222222
2017-02-27 15:22:42.853585 dispatch_queue[3443:148056] 3333333333

//可以看出，执行结果很混乱，属于并发执行,现在打开set_target_queue注释,得到以下结果:
2017-02-27 15:25:06.510355 dispatch_queue[3470:149395] 11111111111
2017-02-27 15:25:06.510405 dispatch_queue[3470:149395] 22222222222
2017-02-27 15:25:06.510423 dispatch_queue[3470:149395] 3333333333
2017-02-27 15:25:06.510438 dispatch_queue[3470:149395] 11111111111
2017-02-27 15:25:06.510452 dispatch_queue[3470:149395] 22222222222
2017-02-27 15:25:06.510465 dispatch_queue[3470:149395] 3333333333
2017-02-27 15:25:06.510477 dispatch_queue[3470:149395] 11111111111
2017-02-27 15:25:06.510491 dispatch_queue[3470:149395] 22222222222
2017-02-27 15:25:06.510501 dispatch_queue[3470:149395] 3333333333
2017-02-27 15:25:06.510512 dispatch_queue[3470:149395] 11111111111
2017-02-27 15:25:06.510524 dispatch_queue[3470:149395] 22222222222
2017-02-27 15:25:06.510536 dispatch_queue[3470:149395] 3333333333
2017-02-27 15:25:06.510548 dispatch_queue[3470:149395] 11111111111
2017-02-27 15:25:06.510560 dispatch_queue[3470:149395] 22222222222
2017-02-27 15:25:06.510575 dispatch_queue[3470:149395] 3333333333
这就是典型的dispatch_set_target并发变FIFO串行执行功能.
{% endcodeblock %}

### 延时函数 dispatch_after

---

{% codeblock lang:objc %}
- void dispatch_after(dispatch_time_t when,dispatch_queue_t queue,dispatch_block_t block);
{% endcodeblock %}
1. 参数1 when指定block执行的时间，
2. 参数2 queue指定block执行的队列形式，
3. 参数3 block指定延时函数接收的闭包.
- void dispatch_after_f(dispatch_time_t when,dispatch_queue_t queue,void *_Nullable context,dispatch_function_t work);
1.跟dispatch_after功能一样.
2.参数3 work指定延时函数接收一个函数指针.

### 原子性操作 Dispatch_barrier

---

dispatch_barrier在多线程编程中用来保证某个值域的原子性。在多线程操作中，同时对于同一个值的读取不会有问题，但如果同时对一个值进行修改就会产生冲突，此时dispatch_barrier可以很好的解决这个问题，dispatch_barrier就像一个盒子，当盒子内的任务没有出来前，盒子外的任务全部维护到一个队列中。
**相关函数如下:**
{% codeblock lang:objc %}
- void dispatch_barrier_sync(dispatch_queue_t queue, dispatch_block_t block);
//将闭包放入同步环境的queue队列中执行.
- void dispatch_barrier_sync_f(dispatch_queue_t queue,void *_Nullable context,dispatch_function_t work);
//将函数放入同步环境中的queue执行
- void dispatch_barrier_async(dispatch_queue_t queue, dispatch_block_t block);
//将闭包放入异步环境的queue队列中执行.
- void dispatch_barrier_async_f(dispatch_queue_t queue,void *_Nullable context,dispatch_function_t work);
//将函数放入异步环境中的queue执行
{% endcodeblock %}

**事例代码如下：**

{% codeblock lang:objc %}
NSMutableDictionary *_vars;
void setVars(NSMutableDictionary *vars) {

	dispatch_queue_t _serialQueue = dispatch_queue_create("this.is.serial.queue", DISPATCH_QUEUE_SERIAL);
	dispatch_barrier_async(_serialQueue, ^{

		_vars = vars;
	});
}

{% endcodeblock %}

### 为一个队列添加属性和获取属性
GCD允许给一个队列通过特定的key值关联属性contenxt,有点类似于使用runtime的objc_associated,在类别中给一个类添加属性，用于实际业务需要.
当key对应的context发生变化时，会触发C函数destructor.
- void dispatch_queue_set_specific(dispatch_queue_t queue, const void *key,void *_Nullable context, dispatch_function_t _Nullable destructor);
//通过key,为一个queue设置context
- void *_Nullable dispatch_queue_get_specific(dispatch_queue_t queue, const void *key);
//通过key,从一个queue读取context
- void *_Nullable dispatch_get_specific(const void *key);
//返回当前子系统特定的上下文(context)子系统(好无力的解释。。。😭)， 如果在一个block块中执行，并且已经设置了context,则用于获取该队列key对应的context,否则返回在目标队列中执行dispatch_get_specific()的结果；如果当前队列是一个全局并发队列,则返回NULL(全局队列由系统派发，所有的设置无效)
示例代码如下:

{% codeblock lang:objc %}
void destructorInvoke(const void *string) {

	NSLog(@"destructor ----->%@",[[NSString alloc] initWithUTF8String:(char *)string]);
}
dispatch_queue_t _serialQueue;
void dispatchSpecific() {

	setSpecific(@"1");
	setSpecific(@"2");
	setSpecific(@"3");
	setSpecific(@"4");
	setSpecific(@"5");
}
void setSpecific(NSString *context) {

	if (!_serialQueue) {

		_serialQueue = dispatch_queue_create("serial.queue", DISPATCH_QUEUE_SERIAL);
	}
	const char *key = "set one context";
	NSLog(@"set string:%@",context);
	dispatch_queue_set_specific(_serialQueue, key, context.UTF8String, &destructorInvoke);

	NSLog(@"context is : %@",[NSString stringWithUTF8String:dispatch_queue_get_specific(_serialQueue,key)]);
}

输出结果:
2017-02-27 16:14:25.026095 dispatch_queue[3855:177340] set string:1
2017-02-27 16:14:25.026151 dispatch_queue[3855:177340] context is : 1
2017-02-27 16:14:25.026166 dispatch_queue[3855:177340] set string:2
2017-02-27 16:14:25.026194 dispatch_queue[3855:177340] context is : 2
2017-02-27 16:14:25.026206 dispatch_queue[3855:177340] set string:3
2017-02-27 16:14:25.026212 dispatch_queue[3855:177396] destructor ----->1
2017-02-27 16:14:25.026225 dispatch_queue[3855:177340] context is : 3
2017-02-27 16:14:25.026228 dispatch_queue[3855:177396] destructor ----->2
2017-02-27 16:14:25.026241 dispatch_queue[3855:177340] set string:4
2017-02-27 16:14:25.026298 dispatch_queue[3855:177340] context is : 4
2017-02-27 16:14:25.026307 dispatch_queue[3855:177396] destructor ----->3
2017-02-27 16:14:25.026315 dispatch_queue[3855:177340] set string:5
2017-02-27 16:14:25.026335 dispatch_queue[3855:177340] context is : 5
2017-02-27 16:14:25.026338 dispatch_queue[3855:177396] destructor ----->4

{% endcodeblock %}

{% note info %} 
PS：
dispatch_queue的知识大致如此，水平有限，如有错误之处，请及时指出 
{% endnote %}
