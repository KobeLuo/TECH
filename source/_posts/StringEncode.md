---
title: Unicode Forms
type: categories
comments: true
date: 2018-11-05 11:16:15
categories: Tools
tags: [编码格式, FormC, FormD, unicode Encode]
---

### [Unicode](https://zh.wikipedia.org/wiki/Unicode)

Unicode是计算机领域的一项业界标准，主要为了解决世界上大部分的文字系统的统一编码问题而存在，因此它记录了差不多世界上全部主流的语言的编码集合。Unicode伴随着通用字符集的标准而发展，同时也以书本的形式[1]对外发表。Unicode至今仍在不断增修，每个新版本都加入更多新的字符。目前最新的版本为2018年6月5日公布的11.0.0[2]，已经收录超过13万个字符（第十万个字符在2005年获采纳）。Unicode涵盖的数据除了视觉上的字形、编码方法、标准的字符编码外，还包含了字符特性，如大小写字母。

<!--more-->
#### Unicode的设计原则

一下内容列举了Unciode设计的十大原则：
- Universality：提供单一、综合的字符集，编码一切现代与大部分历史文献的字符。
- Efficiency：易于处理与分析。
- Characters, not glyphs：字符，而不是字形。
- Semantics：字符要有良好定义的语义
- Plain text：仅限于文本字符
- Logical order：默认内存表示是其逻辑序
- Unification：把不同语言的同一书写系统（scripts）中相同字符统一起来。
- Dynamic composition：附加符号可以动态组合。
- Stability：已分配的字符与语义不再改变。
- Convertibility：Unicode与其他著名字符集可以精确转换。


#### Unicode的编码与实现
大体上来说，Unicode 编码系统可分为`编码方式`和`实现方式`两个层次.

##### 编码方式
统一码的编码方式与ISO 10646的通用字符集概念相对应。目前实际应用的统一码版本对应于UCS-2，使用16位的编码空间。也就是每个字符占用2个字节。这样理论上一共最多可以表示216（即65536）个字符。基本满足各种语言的使用。实际上当前版本的统一码并未完全使用这16位编码，而是保留了大量空间以作为特殊使用或将来扩展。

上述16位统一码字符构成基本多文种平面。最新（但未实际广泛使用）的统一码版本定义了16个辅助平面，两者合起来至少需要占据21位的编码空间，比3字节略少。但事实上辅助平面字符仍然占用4字节编码空间，与UCS-4保持一致。未来版本会扩充到ISO 10646-1实现级别3，即涵盖UCS-4的所有字符。UCS-4是一个更大的尚未填充完全的31位字符集，加上恒为0的首位，共需占据32位，即4字节。理论上最多能表示231个字符，完全可以涵盖一切语言所用的符号。

基本多文种平面的字符的编码为U+hhhh，其中每个h代表一个十六进制数字，与UCS-2编码完全相同。而其对应的4字节UCS-4编码后两个字节一致，前两个字节则所有位均为0。

关于统一码和ISO 10646及UCS的详细关系，见[通用字符集](https://zh.wikipedia.org/wiki/%E9%80%9A%E7%94%A8%E5%AD%97%E7%AC%A6%E9%9B%86)。

##### 实现方式

Unicode的实现方式不同于编码方式。一个字符的Unicode编码是确定的。但是在实际传输过程中，由于不同系统平台的设计不一定一致，以及出于节省空间的目的，对Unicode编码的实现方式有所不同。Unicode的实现方式称为Unicode转换格式（Unicode Transformation Format，简称为`UTF`）

Unicode实现方式的主流编码格式有：
- [UTF-8](https://zh.wikipedia.org/wiki/UTF-8): 
	是一种针对Unicode的可变长度字符编码，也是一种前缀码。它可以用来表示Unicode标准中的任何字符，且其编码中的第一个字节仍与ASCII兼容，这使得原来处理ASCII字符的软件无须或只须做少部分修改，即可继续使用。因此，它逐渐成为邮箱、网页及其他存储或发送文字的应用中，优先采用的编码。

- [UTF-16](https://zh.wikipedia.org/wiki/UTF-16):
	Unicode的编码空间从U+0000到U+10FFFF，共有1,112,064个码位（code point）可用来映射字符. Unicode的编码空间可以划分为17个平面（plane），每个平面包含216（65,536）个码位。17个平面的码位可表示为从U+xx0000到U+xxFFFF，其中xx表示十六进制值从0016到1016，共计17个平面。第一个平面称为基本多语言平面（Basic Multilingual Plane, BMP），或称第零平面（Plane 0）。其他平面称为辅助平面（Supplementary Planes）。基本多语言平面内，从U+D800到U+DFFF之间的码位区块是永久保留不映射到Unicode字符。UTF-16就利用保留下来的0xD800-0xDFFF区块的码位来对辅助平面的字符的码位进行编码。

- 其它的一些编码方式(UTF-7、UTF-32、Punycode、CESU-8、SCSU、GB18030...etc)

### [Unicode Form](https://unicode.org/reports/tr15/)

Unicode主要有四种标准化格式，分别是

标准模式：
- Form C (Normalization Form C)
- Form D (Normalization Form D)

兼容模式：
- Form KC (Normalization Form KC)
- Form KD (Normalization Form KD)

关于标准化格式的内容,请自行查阅相关资料。

这里着重强调的是，Window使用的是UTF-16作为标注的编码方式，而并未使用Unicode的标准化格式，这就意味着你可以使用两个肉眼看上去一模一样的名字（实际上他们的代码点不一样），而Mac OS系统使用的是UTF-8作为标注编码方式，使用Form C作为标准文本格式，这意味着当你使用两个看上去一样的名字时，OS系统会自动将名字区分开。

由于使用上的操作系统的差异，就导致了有时候从服务端返回的名称看上去跟本地一致，其实不一致的问题。

对于采用了其它标准格式或未使用标准格式的服务端，对于服务端返回的名称，则需要把源字符串转化为标准的FormD格式（Mac OS系统底层默认格式），这样才能正常的比较字符串
而当你上传本地文件到服务端时，指定名字也需要反向的使用服务端相应的名字格式。

Mac OS/iOS系统下Foundation库中String的属性代码：

```Objective-C

//Form D
@property (readonly, copy) NSString *decomposedStringWithCanonicalMapping; 

//Form C
@property (readonly, copy) NSString *precomposedStringWithCanonicalMapping;

//Form KD
@property (readonly, copy) NSString *decomposedStringWithCompatibilityMapping;

//Form KC
@property (readonly, copy) NSString *precomposedStringWithCompatibilityMapping;

```






