//
//  File.swift
//  GitHubGists
//
//  Created by Trần Vũ Hưng on 1/29/18.
//  Copyright © 2018 Tran Vu Hung. All rights reserved.
//

import Foundation
import SwiftyJSON

class File: NSObject, NSCoding, ResponseJSONObjectSerializable {
  var filename: String?
  var raw_url: String?
  var content: String?
  
  required init?(_ json: SwiftyJSON.JSON) {
    self.filename = json["filename"].string
    self.raw_url = json["raw_url"].string
  }
  
  init?(name: String?, content: String?){
    self.filename = name
    self.content = content
  }
  
  //MARK: - NSCoding
  func encode(with aCoder: NSCoder) {
    aCoder.encode(filename, forKey: "filesname")
    aCoder.encode(raw_url, forKey: "raw_url")
    aCoder.encode(content, forKey: "content")
  }
  
  required convenience init?(coder aDecoder: NSCoder) {
    let fileName = aDecoder.decodeObject(forKey: "filename") as? String
    let content = aDecoder.decodeObject(forKey: "content") as? String
    
    self.init(name: fileName, content: content)
    raw_url = aDecoder.decodeObject(forKey: "raw_url") as? String
  }
}
