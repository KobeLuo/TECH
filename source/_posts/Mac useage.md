---
title: Mac使用笔记
date: 2016-04-06 17:48:11
type: "categories"
categories: Tools
tags: [常用命令]
---


#### 显示隐藏文件：  
{% note info %} 
显示: `defaults write com.apple.finder AppleShowAllFiles -bool true`
隐藏: `defaults write com.apple.finder AppleShowAllFiles -bool false`

**restart your mac**

{% endnote %}
<!--more-->

#### 常用网址
- [MAC OS OpenSource](https://opensource.apple.com)
- [Mach IPC Interface](http://web.mit.edu/darwin/src/modules/xnu/osfmk/man/)
{% cq %} xxxx xxxx xxxx {% endcq %}


- [Class-dump](https://github.com/KobeLuo/class-dump)
通过可执行文件反解析头文件
class-dump -H [.app文件的路径] -o [输出文件夹路径]