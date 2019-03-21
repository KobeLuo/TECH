---
title: OS X文件权限控制（未完结）
type: categories
comments: true
date: 2019-02-22 09:37:11
categories:
tags:
---
### 用到的工具或技术点
[chmod](http://ahaack.net/technology/OS-X-Access-Control-Lists-ACL.html)
[chflag](https://ss64.com/osx/chflags.html)
[setFile](https://ss64.com/osx/setfile.html)
[GetFileInfo](https://ss64.com/osx/getfileinfo.html)

#### hidden & nohidden 
文件在GUI上隐藏和显示，但在命令行中使用ls依然可以看到该文件
```ruby
$ chflags hidden file
$ chflags nohidden file
```

### apaque & noapaque

```ruby
$ chflags apaque file
$ chflags noapaque file
```

### uchg & nouchg

```ruby
chflags uchg file
chflags nouchg file
```

递归加解锁
```ruby
chflags -R uchg folder
chflags -R nouchg folder
```

### schg & noschg
控制文件权限
```ruby
$ sudo chflags schg file
$ sudo chflags noschg file
```

设置文件的type,该type不能再file attributes中显示，但可以通过GetFileInfo获取
```ruby
$ setFile -t "ABCD" file
$ GetFileInfo -t file
```