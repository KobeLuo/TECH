---
title: GCD系列:代码块(dispatch_block)
date: 2017-03-27 20:25:04
type: "categories"
categories: Mac Develop
tags: [GCD,Dispatch block,dispatch代码块]
---

### dispatch_block

dispatch_block系列函数可以对一段代码进行准确控制，最显著的功能就是可以取消执行的代码块，在实际项目开发中非常有用。
<!--more-->

### 基本函数
---

{% codeblock lang:objc %}
dispatch_block_t dispatch_block_create(dispatch_block_flags_t flags, dispatch_block_t block);
void dispatch_block_perform(dispatch_block_flags_t flags,DISPATCH_NOESCAPE dispatch_block_t block);
void dispatch_block_cancel(dispatch_block_t block);	
long dispatch_block_wait(dispatch_block_t block, dispatch_time_t timeout);	
void dispatch_block_notify(dispatch_block_t block, dispatch_queue_t queue,
dispatch_block_t notification_block);
long dispatch_block_testcancel(dispatch_block_t block);
{% endcodeblock %}



### 函数理解
---
1.使用dispatch_create创建一个基于GCD的代码块,参数flag，指定代码块的执行环境，block是代码执行体。

**关于flag的定义**
{% codeblock lang:objc %}
DISPATCH_ENUM_AVAILABLE_STARTING(__MAC_10_10, __IPHONE_8_0)
DISPATCH_ENUM(dispatch_block_flags, unsigned long
DISPATCH_BLOCK_BARRIER = 0x01,
DISPATCH_BLOCK_DETACHED = 0x02,
DISPATCH_BLOCK_ASSIGN_CURRENT = 0x04,
DISPATCH_BLOCK_NO_QOS_CLASS = 0x08,
DISPATCH_BLOCK_INHERIT_QOS_CLASS = 0x10,
DISPATCH_BLOCK_ENFORCE_QOS_CLASS = 0x20,
);
{% endcodeblock %}

- DISPATCH_BLOCK_BARRIER 保证代码块用于原子性，代码块的代码未执行结束前，下一次调用将进入一个FIFO的等待队列，等待本次代码块执行结束，使用较为安全,若不考虑线程安全可使用DISPATCH_BLOCK_DETACHED，其它flag自行查阅文档。

2.dispatch_block_perform 没有实际使用过，可能是在当前线程中将闭包的执行体放在指定的flag环境中去执行（待认证）.

3.dispatch_block_cancel 取消执行某个block，只有当block还未执行前执行cancel有效，block正在执行无法取消.
4.dispatch_block_wait 等待block执行，直到timeout后继续往下执行代码,如果timeout=DISPATCH_TIME_FOREVER且block永远不被执行，代码将永远等待。
5.dispatch_block_notify(block1,queue,notification_block);注册一个block1的监听，当block1已经完成的时候，会在queue里立即执行notification_block.


### 简要Demo：
---
**Demo1.简单用法**

{% codeblock lang:objc %}
dispatch_block_t _dblock;
void testDispatchBlock() {

	while (_index < 10) {

		createBlockIfNeeded();
		executingBlockOrCancel();
	}
}

NSInteger _index;
void createBlockIfNeeded() {

	if (!_dblock) {

	_dblock = dispatch_block_create(DISPATCH_BLOCK_BARRIER, ^{

		NSLog(@"index -> %lu",_index);
	});
}
}

void executingBlockOrCancel() {

	if ( ++ _index % 2 ) {

		_dblock();
	}else {

		dispatch_block_cancel(_dblock);
		_dblock = nil;
	}
}
{% endcodeblock %}

**输出结果:**

{% codeblock lang:objc %}
2017-02-26 23:15:32.362374 dispatch_block_oc[60994:11193423] index -> 1
2017-02-26 23:15:32.362444 dispatch_block_oc[60994:11193423] index -> 3
2017-02-26 23:15:32.362471 dispatch_block_oc[60994:11193423] index -> 5
2017-02-26 23:15:32.362491 dispatch_block_oc[60994:11193423] index -> 7
2017-02-26 23:15:32.362511 dispatch_block_oc[60994:11193423] index -> 9
{% endcodeblock %}

**Demo2.当block在延时函数中使用**

{% codeblock lang:objc %}
void delayExecutingTask() {

	createBlockIfNeeded();

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), _dblock);
	//sometimes ,you need cancel the block,use dispatch_block_cancel 
	dispatch_block_cancel(_dblock);
}
{% endcodeblock %}

**Demo3.dispatch_block_waite**

{% codeblock lang:objc %}
dispatch_block_t _dblock;
void testDispatchBlock() {

	createBlockIfNeeded();
	executingBlockOrCancel();
}

NSInteger _index;
void createBlockIfNeeded() {

	if (!_dblock) {

	_dblock = dispatch_block_create(DISPATCH_BLOCK_BARRIER, ^{

		[NSThread sleepForTimeInterval:5];
		NSLog(@"index -> %lu",_index);
		});

		NSLog(@"wait BEGIN ");
		dispatch_block_wait(_dblock, dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC));
		NSLog(@"wait END ");
	}
}

void executingBlockOrCancel() {

	if ( ++ _index % 2 ) {

		_dblock();
	}else {

		dispatch_block_cancel(_dblock);
		_dblock = nil;
	}
}
{% endcodeblock %}

**输出结果:**
{% codeblock lang:objc %}
2017-02-26 23:27:27.484894 dispatch_block_oc[61126:11221388] wait BEGIN 
2017-02-26 23:27:29.485858 dispatch_block_oc[61126:11221388] wait END 
2017-02-26 23:27:34.487206 dispatch_block_oc[61126:11221388] index -> 1
{% endcodeblock %}

demo中，在函数createBlockIfNeeded函数中，输出waite BEGIN之后，dispatch_block_waite函数将等待两秒，再输出waite END,之后才执行函数executingBlockOrCancel();

**Demo4.dispatch_block_notify**

{% codeblock lang:objc %}
dispatch_block_t _dblock;
void testDispatchBlock() {

	NSLog(@"BEGIN");
	createBlockIfNeeded();
	_dblock();
}

NSInteger _index;
void createBlockIfNeeded() {

	if (!_dblock) {

		_dblock = dispatch_block_create(DISPATCH_BLOCK_BARRIER, ^{

		[NSThread sleepForTimeInterval:5];
		NSLog(@"index -> %lu",_index);
	});

	dispatch_block_notify(_dblock, dispatch_get_main_queue(), ^{

		NSLog(@"BLOCK EXECUT COMPLETED");
	});
	}
}

void executingBlockOrCancel() {

	if ( ++ _index % 2 ) {

		_dblock();
	}else {

		dispatch_block_cancel(_dblock);
		_dblock = nil;
	}
}
{% endcodeblock %}
**输出结果:**

{% codeblock lang:objc %}
2017-02-26 23:36:30.105075 dispatch_block_oc[61245:11242889] BEGIN
2017-02-26 23:36:35.106363 dispatch_block_oc[61245:11242889] index -> 0
2017-02-26 23:36:35.122696 dispatch_block_oc[61245:11242889] BLOCK EXECUT COMPLETED
{% endcodeblock %}

{% note info %} 
目前，使用了一些Dispatch_block的基本用法，更复杂的在多线程中的用法会陆续记载。 
{% endnote %}

