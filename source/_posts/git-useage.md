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

## git init 初始化Git仓库
```ruby
git init 
```
`Create an empty Git repository or reinitialize an existing one`
命令执行后，在当前目录生成一个.git的隐藏目录，内含git仓库需要的资源。
[更多用法](https://git-scm.com/docs/git-init)

<!--more-->	

## git clone 克隆仓库
```ruby
git clone http://code.site.you.clone  localpath

```
`http://code.site.you.clone` 更换成你克隆的地址
`localpath` 指定你本地克隆的地址，也可省去，默认是克隆到当前路径下
[更多用法](https://git-scm.com/docs/git-clone)

## git remote 远程仓库

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
[更多用法](https://git-scm.com/docs/git-remote)
以上内容熟悉后，本地仓库克隆及commit及push基本已经可以了，
关于多账号的sshkey问题，请[左转](http://www.kobev5.com/TECH/2017/04/07/Hexo-useage-note/#jump)


## git branch 分支操作
```swift
git branch 
git branch --list
//显示本地已有的分支

git branch newBranch
//创建本地newBranch分支，不切换当前分支

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
[更多用法](https://git-scm.com/docs/git-branch)

## git add 添加到本地仓库
```swift
git add .
//将当前变更添加到本地仓库

git add . -v
//将当前变更添加到本地仓库，并显示细节 `-v` == `--verbose`

git add . -e
//使用vim打开已变更内容文件，可编辑，:wq保存后添加到本地仓库
```
[更多用法](https://git-scm.com/docs/git-add)


## git commit 提交代码
```swift
git commit -m "your commit message" 
//直接通过命令行输入提交信息，并将代码提交到本地仓库

git commit
//使用vim打开本次提交内容，在vim中输入详细的提交信息,一般`git merge`后解决冲突使用这种方式更恰当

git commit --amend
//使用vim打开上次提交message,`:wq`保存后作为本次提交信息提交到本地仓库
```
[更多用法](https://git-scm.com/docs/git-commit)

## git checkout 分支创建切换
```swift
git checkout anotherBranch
//从当前分支切换到anotherBranch分支

git checkout -b newBranch
//创建一个新的分支newBranch并切换到newBranch分支

git checout -B oneBranch
//创建或重置oneBranch分支并切换到oneBranch分支。

```
[更多用法](https://git-scm.com/docs/git-checkout)

## git push
```swift
git push 
//将已提交至本地仓库代码push到远程分支，默认push到本地分支所对应的远程分支

git push origin thebranch
//将已提交至本地仓库代码push到远程指定的thebranch分支上，如果没有则创建.

git push origin thebranch -v
//功能同上，同时展示更多细节

git push origin thebranch -q
//功能同上，尽可能的省略更多细节 跟`-v`相反

git push origin thebranch -f 
git push -f
//强制push到远程thebranch分支或当前分支所对应的远程分支
```
[更多用法](https://git-scm.com/docs/git-push)


## git log
```swift
git log 
//查看当前分支提交记录,按`q`退出
```
[更多用法](https://git-scm.com/docs/git-log)


## git reflog
```swift
git reflog 
//查看所有分支的提交记录和操作过程，按`q`退出
```
[更多用法](https://git-scm.com/docs/git-reflog)


## git diff
```swift
git diff filepath
//查看filepath下的文件的变更  

git diff branchName filepath
//当前分支的filepath文件与branchName分支的filepath文件对比 

git diff HEAD filepath
//查看filepath文件与HEAD所指向的节点的filepath文件对比

git diff commitId filepath
//当前分支的filepath文件与指定commitId的提交时的filepath文件对比

```
[更多用法](https://git-scm.com/docs/git-diff)


## git reset 代码回滚
```swift

git reset HEAD
//将当前分支节点指向HEAD节点，其实没任何变化

git reset HEAD~1
//将当前分支指向HEAD节点的上一个节点,并将上一次提交的内容回滚.

git reset commitID
//将当前分支指向commitID指向的节点,并将commit节点之后所提交的所有内容回滚.

git reset --soft commitID
//

git reset --hard commitID

```
[更多用法](https://git-scm.com/docs/git-reset)


## git fsck --lost-found 
找回已经删除的文件，但是存在着add记录，博主未测试[链接](https://www.cnblogs.com/hope-markup/p/6683522.html)
