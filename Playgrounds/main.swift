//
//  main.swift
//  Playgrounds
//
//  Created by Chris Eidhof on 10/10/15.
//  Copyright © 2015 Chris Eidhof. All rights reserved.
//

import Foundation

struct File {
    static var fm = NSFileManager.defaultManager()
    
    var path: String
    
    init(path: String) {
        self.path = path
    }
    
    private var attributes: [String:AnyObject] {
        return (try? File.fm.attributesOfItemAtPath(path)) ?? [:]
    }
    
    private var fileType: String {
        return (attributes[NSFileType] as? String) ?? ""
    }
    
    static var currentDirectory: File {
        return File(path: File.fm.currentDirectoryPath)
    }
    
    var isDirectory: Bool {
        return fileType == NSFileTypeDirectory
    }
    
    var subdirectories: [File] {
        return (File.fm.subpathsAtPath(path) ?? []).map(File.init).filter { $0.isDirectory }
    }
    
    var name: String {
        return (path as NSString).lastPathComponent
    }
    
    var fileExtension: String {
        return (path as NSString).pathExtension
    }
    
    subscript(component: String) -> File {
        return File(path: (path as NSString).stringByAppendingPathComponent(component))
    }
    
    func contents() throws -> String {
        return try String(contentsOfFile: path)
    }
}

extension String {
    var lines: [String] {
        return componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
    }
}

extension Array {
    func group(inGroup: Element -> Bool) -> [[Element]] {
        let initial: [[Element]] = [[]]
        return reduce(initial) { (var currentGroups, element) -> [[Element]] in
            let x = inGroup(element)
            let y = currentGroups.last?.last.map(inGroup)
            if x == y {
                currentGroups[currentGroups.count-1].append(element)
            } else {
                currentGroups.append([element])
            }
            return currentGroups
        }.filter { !$0.isEmpty }
    }
}

enum PlaygroundBit {
    case Markdown(String)
    case Swift(String)
    
    var markdown: String {
        switch self {
        case .Markdown(let s): return s
        case .Swift(let s): return ["```swift", s, "```"].joinWithSeparator("\n")
        }
    }
}

struct PlaygroundText {
    var input: String
    
    private var playgroundBits: [PlaygroundBit] {
        let isMarkdownLine: String -> Bool = { $0.hasPrefix("//:") }
        return input.lines.group(isMarkdownLine).flatMap { linesForBit in
            guard !linesForBit.isEmpty else { return nil }
            if linesForBit.first.map(isMarkdownLine) == true {
                let string = linesForBit.map { (s: String) in
                    return (s as NSString).substringFromIndex(4)
                }.joinWithSeparator("\n")
                return .Markdown(string)
            } else {
                let string = linesForBit.joinWithSeparator("\n")
                return .Swift(string)
            }
        }
    }
    
    var markdown: String {
        return playgroundBits.map { $0.markdown }.joinWithSeparator("\n\n")
    }
}


let cwd = File.currentDirectory
let playground = cwd.subdirectories.filter { $0.fileExtension == "playground" }.first!
let swiftFile = playground["Contents.swift"]
let contents = try! swiftFile.contents()
let playgroundText = PlaygroundText(input: contents)
print(playgroundText.markdown)