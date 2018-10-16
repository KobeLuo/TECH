---
title: git深入理解
type: categories
comments: true
date: 2018-10-16 09:53:11
categories: tools
tags: 
- git理解
- git 
- git进阶
---

在[git使用](http://www.kobeluo.com/TECH/2016/07/15/git-useage)这篇文章中，博主列出了常用的git命令和一些使用方法，可以应付日常的开发工作，熟悉git的朋友应该知道，git是一个非常强大的工具，能使用git的常规命令只能说你掌握了git的基本操作，如果还需要更深入的理解git，理解每一条命令背后执行的操作和含义，则需要更为深刻的理解git的运行机制和设计原理，博主对于git的理解也很浅显，该文在谈及git内涵外，也希望有更多的大神能够相互交流，以此增进对git的理解，比较进步源于分享嘛 ^.^。
<!-- more -->

## 官方文档
先列出官方文档:
- [git官网](https://git-scm.com/)
- [git常用命令](https://services.github.com/on-demand/downloads/github-git-cheat-sheet.pdf)
- [git权威指南](https://git-scm.com/doc)

## git仓库介绍
### 关于git仓库基础构造的官方文档如下图
![git仓库基础结构](git-structure.png)
![git仓库细节](git-structure-desc.png)

### 个人理解
#### git仓库代码树的三大状态: 

`Modified：` 代表被检出的代码已经被更改，但是还没有添加到暂存区，当然也没有提交到本地仓库；
`Staged：` 代表被检出的代码已经加入了暂存区，它将是你下一次执行commit时提交的变更内容；
`Committed：` 代表你的代码已经安全永久的提交到了本地仓库。

#### git仓库的三大仓库区

`git repository` 本地仓库，git最重要的部分，存储了一个工程所有的git信息和数据对象。
`Working Directory` 工作目录或工作区，是指当你执行`git checkout branch`时，存储branch所指的节点的数据和git信息，以提供你增删改查。 
`Staging Area` 暂存区 介于检出代码于modified和committed之间的一种状态区域，当你执行`git add -a`时，将已经modified的代码添加到暂存区，以供下一次commit时将暂存区的变更提交到本地仓库。

#### 从实际项目出发理解

1.执行`git clone`时，将远程代码clone到本地，此时建立了git本地仓库，同时默认工作区是master分支，此时暂存区为空；
2.执行`git checkout branch`时，将branch分支的代码作为工作区，此时工作区从master分支变更为branch分支的代码内容和git信息；
3.现在开始增删改查项目的内容；
4.当你保存更改时，git将变更的内容标记为modified；
5.此时你可能需要提交代码了；执行 `git add .`将 已更改的代码提交到暂存区，被更改的代码的状态从`Modified`变更为`Staged`；
6.此时执行命令`git commit`提交代码，将暂存区的变更快照提交到本地仓库，变更代码状态从`Staged`变更为`Committed`，自此你的变更内容将永久安全的存储到本地仓库。

## 文件的记录过程
每个文件在working copy中的状态有两种: tracked(被跟踪) or untracked(未被跟踪)
```swift
Remember that each file in your working directory can be in one of two states: tracked or untracked. 
Tracked files are files that were in the last snapshot; they can be unmodified, modified, or staged.
In short, tracked files are files that Git knows about.
```
被跟踪的文件的文件状态存储在最后一次快照中。
![git文件全状态](file-status-all.png)
