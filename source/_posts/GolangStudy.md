---
title: Golang study record
type: categories
comments: true
date: 2017-05-22 15:50:12
categories: Golang
tags: 
- Golang学习
---

# Go相关网站
- [Go教程中文网](http://c.biancheng.net/golang/)
- [Go安装教程](https://golang.org/doc/install?download=go1.12.5.darwin-amd64.pkg)


# Go基本命令
```golang
//command line tool 跳转到 hello文件夹下
$ cd /path/to/hello

//编译该目录下的.go文件，生成可执行文件
$ go build 

//执行可执行文件 
$ ./hello  

//清除可执行文件
$ go clean -i 

```

---
# Go基础语法

## 变量命名
```go
var a int
var b string
var c []float32
var d func() bool
var e struct {
		
	x int
}

以上申明方式等同于
var (
	
	a int
	b string
	...
)
```
## 变量初始化
- float和int默认值为0;
- 字符串默认空串;
- 布尔型默认为bool;
- 切片、函数、指针变量默认为nil;
- 初始化的同时赋值  var a  int = 10,省略int 编译器将尝试使用右值来推导变量类型
- 对于float，如果没有指定类型，则尽量提高精度
- a := 10,表示声明并赋值，这种方式只适用于未定义的变量，若变量被定义过则会编译失败
- a, b := funcA() 表示funcA函数返回两个变量，多变量必须保证左边至少有一个变量是未被定义过的
- go支持多重赋值，a := 1 b := 2 a,b = b,a
- go中匿名变量使用`_`表示，匿名变量不占用命名空间，不会分配内存。匿名变量与匿名变量之间也不会因为多次声明而无法使用。
- go中，byte是uint8，可用来表示传统ASCII的单个字节,rune是int32的别名，用来处理中文日文等复合型字符串。

## 浮点数
float32大概可以提供6个十进制数的精度，float64大概可以提供15个十进制数的精度；通常应该使用float64，因为float32类型误差很容易扩散，它能表示的值并不大，一下代码将出现问题:
```go
var f float32 = 16777216 // 1<<24
fmt.Println(f == f+1) // "true"
```
- 小数点前面或后面的数字都可以被省略(例如: .717和 1.)，很大（小）的数则最好使用科学计数法，如：
```go
const Avogadro = 6.02214129e23  // 阿伏伽德罗常数
const Planck   = 6.62606957e-34 // 普朗克常数
```


