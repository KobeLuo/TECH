---
title: git-config
type: categories
comments: true
date: 2019-09-21 09:37:05
categories:
tags:
---

### Git账号密码变更后,本地pull或push代码将失败，运行一下命令，再次操作git会提示重新输入密码.

```swift
git config --global credential.helper osxkeychain
```
