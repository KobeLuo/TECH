//
//  String+Path.swift
//  NDrive_Sync
//
//  Created by KobeLuo on 01/08/2017.
//  Copyright © 2017 NHN. All rights reserved.
//

import Cocoa

extension String {
	
    public var lastPathComponent: String {
		
        let str = self.decomposedStringWithCanonicalMapping
        
        if str.characters.count <= 1 { return "" }
        
        var name = ""
        for (_, value) in str.characters.enumerated().reversed() {
            
            if value == "/" {
                
                if name != "" { break }
            }else { name = String(value) + name }
        }
        
        return name
	}
	
    public var pathComponents: [String] {
		
        var results = [String]()
        var resultCnt = 0
        let str = self
        let strcnt = str.characters.count
        var component: String? = nil
        
        if str == "/" { results.append("/"); return results }
        
        var pre: Character? = nil
        var pathRepeat = false
        
        for (index,value) in str.characters.enumerated() {
            
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
	
    public var name: String {
	
		return self.lastPathComponent
	}
	
    public func appendingPathComponent(path: String?, regularly: Bool = false) -> String {
		
		guard let path = path else { return self }
        
        var str = self; var name = path
        if regularly == false {
            
            str = pathRegularly(of: self); name = pathRegularly(of: path)
        }
        
        if let firstchar = name.characters.first, firstchar == "/" { return str + name }
		return str + "/" + name
	}
    
    public func apc(_ path: String, _ regularly: Bool = true) -> String {
        
        return appendingPathComponent(path: path, regularly: regularly)
    }
	
    private func pathRegularly(of str: String) -> String {
        
        var result = ""
        var prechar: Character = "1"
        let strcnt = str.characters.count
        for (index,char) in str.characters.enumerated() {
            
            if char != "/" || prechar != "/" {
                
                if index == strcnt - 1 && char == "/" { continue }
                result.append(char)
            }
            
            prechar = char
        }
        
        if let lastchar = result.characters.last, lastchar == "/" { result.characters.removeLast() }
        
        return result
    }
    
	@discardableResult public func deleteByLastComponents() -> String {

		return ((self as NSString).deletingLastPathComponent as String)
	}
	
	public func componentsBy(_ str: String) -> [String] {
		
		return (self as NSString).components(separatedBy:str)
	}
	// Kobe, func spaceESC is incorrect.
	public func spaceESC() -> String {
		
		var path = self
		let string = "'\' "
		path = path.replacingOccurrences(of: " ", with: string)
		return path
	}
	
	public var parentPath: String {
		
		return self.deleteByLastComponents()
	}
	
	public var fileUrlId: String? {
	
		let fileUrl = NSURL.init(fileURLWithPath: self)
		
		if let refURL = (fileUrl as NSURL).perform(#selector(NSURL.fileReferenceURL))?.takeUnretainedValue() as? NSURL {

			return refURL.description
		}
		
		return nil
	}
	
	public var path: String? {
		
		if let fileUrl = NSURL.init(string: self) {
			
			return fileUrl.path
		}
		return nil
	}
	
	public func hasCommonPrefixPath(_ path: String) -> Bool {
		
		var common = false
		
		guard self.hasPrefix(path) else { return common }
		
		if self == path { return true }
		
		let newPath = path.appendingPathComponent(path: "/").appending("/")
		
		guard self.hasPrefix(newPath) else { return common }
		
		common = true
		
		return common
	}
}
