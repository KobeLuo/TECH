---
title: Git使用
type: categories
comments: true
date: 2018-02-15 19:15:50
categories:
tags: 
- Git
- 常用命令
---

该文记录git常用命令和使用方法，记录的博主平时工作所需的一些基础命令，并不能保证完整性和正确性，一般情况下的git使用基本上是满足的，当然如果您有一些特殊的需求，还是需要多查阅[官方文档](https://git-scm.com/)

## 1. git init 初始化Git仓库
```ruby
git init 
```
- Create an empty Git repository or reinitialize an existing one
命令执行后，在当前目录生成一个.git的隐藏目录，内含git仓库需要的资源。

<!--more-->	

## 2. git clone 克隆仓库
```ruby
git clone http://code.site.you.clone  localpath

```
`http://code.site.you.clone` 更换成你克隆的地址
`localpath` 指定你本地克隆的地址，也可省去，默认是克隆到当前路径下

## 3. git remote 远程仓库

```swift

git remote
//显示本地已设置的远程仓库的key

git remote -v 
//查看本地仓库指向的远程仓库地址, -v == --verbose

git remote set-url origin https://remote.site.com   
//设置远程仓库地址

git remote add origin https://remote.site1.com
git remote add key1 https://remote.site2.com
//添加远程仓库地址，注意origin key1在本地是唯一的，多个远程地址key不能重复

git remote get-url origin
git remote get-url key1
//获取指定key对应的远程仓库地址

git remote rename oldkey newkey
//更改远程地址对应的key名

git remote remove newkey
//通过key删除本地远程仓库
```
以上内容熟悉后，本地仓库克隆及commit及push基本已经可以了，
关于多账号的sshkey问题，请[左转](http://www.kobev5.com/TECH/2017/04/07/Hexo-useage-note/#jump)
## 4. git branch
```swift
git branch 
git branch --list
//显示本地已有的分支

git branch -a 
//显示本地和远程已有的分支列表

git branch -d
//

git branch -D
//

t1branch

```

## 5. 
```swift

```
## 6. 
```swift

```
## 7. 
```swift

```
## 8. 
```swift

```
## 9. 
```swift

```
## 10. 
```swift

```
## 11. 
```swift

```
## 12. 
```swift

```
## 13. 
```swift

```
## 14. 
```swift

```
