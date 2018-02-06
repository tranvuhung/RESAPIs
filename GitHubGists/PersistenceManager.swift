//
//  PersistenceManager.swift
//  GitHubGists
//
//  Created by Trần Vũ Hưng on 2/6/18.
//  Copyright © 2018 Tran Vu Hung. All rights reserved.
//

import Foundation

enum Path: String {
  case Public = "Public"
  case Starred = "Starred"
  case MyGists = "MyGists"
}

class PersistenceManager {
  class func saveArray<T: NSCoding>(toSave array: [T], path: Path){
    let filePath = documentDirectory().appending(path.rawValue)
    NSKeyedArchiver.archiveRootObject(array, toFile: filePath)
  }
  
  class func loadArray<T: NSCoding>(path: Path) -> [T]?{
    let filetPath = documentDirectory().appending(path.rawValue)
    let result = NSKeyedUnarchiver.unarchiveObject(withFile: filetPath)
    return result as? [T]
  }
  
  class private func documentDirectory() -> String {
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    let document = paths[0] as String
    return document
  }
}
