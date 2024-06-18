// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import Foundation
import ArgumentParser // apple/swift-argument-parser ~> 1.4
import Path // mxcl/Path.swift ~> 1.4

let dateTimeRegex = /^\d{8}T\d{6}--/

extension Path {
    var creationTime: Date {
        let fileManager = FileManager.default
        do {
            let attributes = try fileManager.attributesOfItem(atPath: self.string)
            // This fails on Linux
            if let creationDate = attributes[.creationDate] as? Date {
                return creationDate
            } else {
                print("Could not get creation date")
                return Date()
            }
        } catch let error  {
            print("Error getting file attributes: \(error)")
            return Date()
        }
    }
}

func dateify(_ path: Path) throws {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss--"
    // this is necessary because TimeZone.gmt is not available on Linux :(
    dateFormatter.timeZone = TimeZone.init(identifier:"GMT")

    if (try? dateTimeRegex.prefixMatch(in: path.basename())) != nil {
        print("File already in dateify format: \(path)")
        return
    }
    let datePrefix = dateFormatter.string(from: path.creationTime)
    let newName = "\(datePrefix)\(path.basename())"
    let newPath = path.parent/newName
    try path.move(to:newPath)
    print("Renamed \(path.basename()) to \(newName)")
}

func unDateify(_ path: Path) throws {
    guard let matched = try? dateTimeRegex.prefixMatch(in: path.basename()) else {
        print("Not in dateify format: \(path)")
        return
    }
    let newName = path.basename()[matched.range.upperBound...]
    let newPath = path.parent/newName
    try path.move(to:newPath)
    print("Renamed \(path.basename()) to \(newName)")
}

@main
struct Main: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Rename file by adding/removing a date-time prefix in the format yyyymmddThhmmss--")

    @Flag(name: .shortAndLong, help: "Undo the renaming, removing the date-time prefix")
    var undo: Bool = false

    @Argument(help: "File or files to rename")
    var files: [String]

    func run() throws {
        let action = undo ? unDateify : dateify
        for filePath in files {
            let path = Path.cwd/filePath
            try action(path)
        }
    }
}

