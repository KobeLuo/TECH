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
//查看本地仓库指向的远程仓库地址, `-v` == `--verbose`

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


## 4. git branch 分支操作
```swift
git branch 
git branch --list
//显示本地已有的分支

git branch -a 
//显示本地和远程已有的分支列表

git branch -d theBranch
//删除theBranch,有两种情况无法删除.
//1.当前分支就是theBranch,你需要切换到其它分支删除theBranch分支；
//2.theBranch分支的代码没有完全合并，首先你需要把代码合并到其它需要合并的分支。

git branch -D theBranch
//强行删除theBranch,如果当前分支在theBranch,则删除失败。

git push origin :theBranch
//删除远程theBranch分支

git branch -m theBranch newBranch
//将theBranch分支 更名为 newBranch分支，git reflog的所有结果也将同时变更

git branch -M theBranch newBranch
//官方定义，`move/rename a branch, even if target exists`，个人感觉非常不安全的操作方式.

git branch --merged
//仅打印已经合并过的分支列表

git branch --no-merged
//仅打印未合并的分支列表
```

## 5. git add 
```swift
git add .
//将当前变更添加到本地仓库

git add . -v
//将当前变更添加到本地仓库，并显示细节 `-v` == `--verbose`

git add . -e
//使用vim打开已变更内容文件，可编辑，:wq保存后添加到本地仓库

```
## 6. git commit 提交代码
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
