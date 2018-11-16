---
title: Swift 桥接OC代码重构
type: categories
comments: true
date: 2018-07-05 10:48:11
categories: Mac Develop
tags: [代码共享, 片段代码]
---

博主目前从事NAVER旗下公司的一个虚拟云盘工作开发，开发语言选择了Swift，但是Objective-C中有一些非常方便的API函数在Swift中并没有提供，早起博主直接使用了官方提供的[bridge](https://stackoverflow.com/questions/24002369/how-to-call-objective-c-code-from-swift)方案来桥接OC部分代码，这样可以方便的使用OC的API，但是这也带来一个性能问题，每次桥接的过程会有一定的耗时；

如果你的项目只是一个普通的信息展示，调用的频次不高，对于性能的优化要求可能就相对较低，但如果你的项目是高频次调用这些API，<!--more-->并且对性能的要求极尽所能，可能你就会对每一行代码的执行效率和耗时做严格的审查，为了提供性能，可能需要将OC函数自己实现，分享部分代码，以供参考。

### String Extension 

#### lastPathComponents
```Swift

public var lastPathComponent: String {
        
        let str = self.decomposedStringWithCanonicalMapping
        
        if str.count <= 1 { return "" }
        
        var name = ""
        for (_, value) in str.enumerated().reversed() {
            
            if value == "/" {
                
                if name != "" { break }
            }else { name = String(value) + name }
        }
        
        return name
}

```
关于String的格式 FormC 和 FormD，请[右转](http://www.kobeluo.com/TECH/2018/11/05/StringEncode/)

#### pathComponents
```Swift
public var pathComponents: [String] {
		
    var results = [String]()
    var resultCnt = 0
    let str = self
    let strcnt = str.count
    var component: String? = nil
    
    if str == "/" { results.append("/"); return results }
    
    var pre: Character? = nil
    var pathRepeat = false
    
    for (index,value) in str.enumerated() {
        
        if value == "/" {
            
            if pre == "/" { pathRepeat = true }else {
                
                if let com = component { results.append(com); resultCnt += 1 }
                component = nil
            }
        }else {
            
            if pathRepeat || (resultCnt == 0 && pre == "/") {
                
                pathRepeat = false; results.append("/"); resultCnt += 1
            }
            if component == nil { component = "" }
            component?.append(value)
        }
        
        if index == strcnt - 1 {
            
            if let com = component { results.append(com) }
            else { results.append("/") }
            
            resultCnt += 1
        }
        
        pre = value
    }
    
    return results
}
```

#### pathRegularly 
该函数是一个基础函数，服务于其它函数，服务于其它函数的内部函数。
```Swift
private func pathRegularly(of str: String) -> String {
    
    var result = ""
    var prechar: Character = "1"
    let strcnt = str.count
    for (index,char) in str.enumerated() {
        
        if char != "/" || prechar != "/" {
            
            if index == strcnt - 1 && char == "/" { continue }
            result.append(char)
        }
        
        prechar = char
    }
    
    if let lastchar = result.last, lastchar == "/" { result.removeLast() }
    
    return result
}
```

#### appendingPathComponent
```Swift

public func appendingPathComponent(path: String?, regularly: Bool = false) -> String {
	
	guard let path = path else { return self }
    
    var str = self; var name = path
    if regularly == false {
        
        str = pathRegularly(of: self); name = pathRegularly(of: path)
    }
    
    if let firstchar = name.first, firstchar == "/" { return str + name }
	return str + "/" + name
}

```

[点我下载String+path.swift](String+Path.swift)


