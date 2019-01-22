---
title: git使用
type: categories
comments: true
date: 2016-07-15 19:15:50
categories: Tools

tags: 
- git
- 常用命令
---

该文记录git常用命令和使用方法，记录的博主平时工作所需的一些基础命令，并不能保证完整性和正确性，一般情况下的git使用基本上是满足的，当然如果您有一些特殊的需求，还是需要多查阅[官方文档](https://git-scm.com/)

[git权威指南](https://git-scm.com/book/en/v2)

## git help 查看帮助文档
```swift
git help init
//查看git init 的帮助文档命令，其余的类推
```

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
git remote add bookmark1 https://remote.site2.com
//添加远程仓库地址，注意origin bookmark1在本地是唯一的，多个远程地址bookmark不能重复

git remote get-url origin
git remote get-url bookmark1
//获取指定bookmark对应的远程仓库地址

git remote rename bookmark1 bookmark2
//更改bookmark名

git remote remove bookmark2
//通过bookmark删除本地远程仓库
```
[更多用法](https://git-scm.com/docs/git-remote)

## git config 配置
```swift
git config --global
//使用全局配置文件

git config --system
//使用系统配置文件

git config --local
//使用本地仓库的配置文件

git config -f filepath
//使用指定路径下的配置文件

git config -l 
//列出配置文件信息列表

git config --global/--systme/--local user.name "yourname"
//配置全局/系统/本地仓库的commit时的用户名

git config --global/--systme/--local user.email "youremail"
//配置全局/系统/本地仓库的commit时的邮箱
```


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

git branch -v
//打印当前分支最后一次commit的文件列表

git branch --merged
//仅打印已经合并过的分支列表

git branch --no-merged
//仅打印未合并的分支列表
```
[更多用法](https://git-scm.com/docs/git-branch)

## git status 代码状态
```swift
git status 
//获取working copy的代码状态

git status -s
//更简单的展示working copy代码变更

```
[更多用法](https://git-scm.com/docs/git-status)

## git stash 代码暂存
```swift

git stash 
//将当前分支的代码暂存

git stash pop 
//将最后一次暂存的代码恢复

git stash -p path/to/file
//暂存某一个文件的内容，执行命令后要选择'y',暂存成功后，该文件将从本地变更中移出。

git stash -p -- path/to/file1 path/to/file2
//暂存多个文件内容，执行命令后需要多次选择‘y’,使用git stash pop即可恢复暂存代码

git stash list
//列出所有stash列表

git stash drop
//丢弃最后一次代码暂存内容
```
[更多用法](https://git-scm.com/docs/git-stash)

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

## git rm 删除文件
```swift
git rm filepath
//删除指定的文件，该文件必须被git标记为tracked的文件

git rm --cached filepath
//从staged中删除filepath，filepath文件将变更为untracked状态，不会真正将文件删除掉

git rm -f filepath
//强制将filepath文件删除掉，同时该文件的所有记录也将从git的快照中删除。
```
[更多用法](https://git-scm.com/docs/git-rm)

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

git checkout .
//将本地所有变更内容reset到当前分支的HEAD状态，即undo本地所有变更内容

git checkout -- path/to/file1 path/to/file2
//undo部分本地文件变更

```
[更多用法](https://git-scm.com/docs/git-checkout)

## git pull
```swift
git pull
//默认拉取当前所在分支的全程分支代码，并合并到本地分支

git pull origin branch
//拉取远程变更历史，并合并变更
```
[更多用法](https://git-scm.com/docs/git-pull)

## git fetch
```swift
git fetch 
//拉取仓库默认远端的所有历史

git fetch bookmark
//拉取仓库指定的bookmark指向的远端所有历史
```
[更多用法](https://git-scm.com/docs/git-fetch)

## git rebase
```swift
git rebase branch
//将branch分支的代码rebase到当前分支
```
rebase 和 merge 之间的使用，一直是比较有争议的，博主两个都使用，都遇到一些不好处理的地方，这里不做评价，请自行查阅官方文档。
[更多用法](https://git-scm.com/docs/git-rebase)

## git merge
```swift
git merge branch
//合并本地branch分支代码到当前分支

git merge bookmark branch
//合并bookmark所在的远程branch分支代码到当前分支
```
[更多用法](https://git-scm.com/docs/git-merge)

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


## git mv 文件移动
```swift
git mv file_from file_to
//将file_from文件更名为file_to
```
[更多用法](https://git-scm.com/docs/git-mv)

## git log
```swift
git log 
//查看当前分支提交记录,按`q`退出

git log --oneline --decorate
//查看提交记录，可在头部查看当前HEAD指针指向哪个分支

git log --oneline --decorate --graph --all
//查看提交记录，并且可以看到当前HEAD指针指向，同时可以看到分支结构图。
```
[更多用法](https://git-scm.com/docs/git-log)


## git tag
```swift
git tag
//查看tag列表

git tag -l 
//查看tag列表,等同于 git tag --list

git tag -l "v1.2*"
//列出所有tag中包括v1.2前缀的tag列表

git tag -a v1.2 -m "your tag descrption”"
//以当前分支创建v1.2tag，tag的信息为“your tag descrption”

git show v1.2
//显示tag v1.2的详细信息

git tag v1.3 -lw
//轻量级的tag,仅仅是打一个tag名，不支持跟-a -s或-m可选参数


git push origin v1.4
//将v1.4的tag push到远端仓库

git push origin --tags
//将一对tagspush到服务端

git tag -d v1.4
//删除v1.4所指的tag

git checkout v1.4
//将当前working copydetach到HEAD状态，显示v1.4tag所指的内容

git checkout -b v14branch v1.4
//以v1.4tag为基准创建一个新的分支v14branch，并切换当前working copy到v14branch
```
[更多用法](https://git-scm.com/docs/git-tag)


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
//将当前分支节点指向commitID指向的节点位置，并将commitID节点之后的提交内容回滚.

git reset --hard commitID
//将当前分支节点指向commitID指向的节点位置，并将commitID节点之后的提交内容全部删除.
//如果commitID之后的内容没有被push到远端服务器，那么`git reset --hard`将是非常危险的操作。

```
[更多用法](https://git-scm.com/docs/git-reset)

git reset 是具有一定危险性的操作方式，博主希望大家在执行命令前，一定先测试一下命令是否正确，是否能达到你想要的要求，千万不可带着试一试的态度去执行`git reset --hard`命令，很可能会导致你的代码丢失.


## git alias
```swift
git config --global alias.co checkout
git co branch 
//等同于  git checkout branch

git config --global alias. br branch
git config --global alias.ci commit
git config --global alias.st status

git config --global alias.unstage 'reset HEAD --'
git unstage filepath
//等同于 git reset HEAD -- filepath

git config --global alias.last 'log -1 HEAD'
git last
//查看最后一次commit日志

git config --global alias.visual '!gitk'
//maybe you want to run an external command, rather than a Git subcommand. In that case, 
//you start the command with a ! character. This is useful if you write your own tools that work with a Git repository.

```


## git version 查看版本信息
```swift
git --version
//查看当前系统下的git版本信息
```

## git fsck --lost-found 
找回已经删除的文件，但是存在着add记录，博主未测试[链接](https://www.cnblogs.com/hope-markup/p/6683522.html)

## git ls-files 列出工程的所有忽略文件
```swift
git ls-files --other --ignored --exclude-standard
```

## 友情推荐

- [git学习网站](https://learngitbranching.js.org/?demo)

