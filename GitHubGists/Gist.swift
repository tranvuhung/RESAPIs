//
//  Gist.swift
//  GitHubGists
//
//  Created by Trần Vũ Hưng on 1/17/18.
//  Copyright © 2018 Tran Vu Hung. All rights reserved.
//

import Foundation
import SwiftyJSON

class Gist: NSObject, NSCoding, ResponseJSONObjectSerializable {
  var id: String?
  var gistDescription: String?
  var ownerLogin: String?
  var ownerAvatarUrl: String?
  var url: String?
  var files:[File]?
  var created: Date?
  var updated: Date?
  
  static let sharedDateFormatter = Gist.dateFormatter()
  
  required init(_ json: JSON) {
    self.gistDescription = json["description"].string
    self.id = json["id"].string
    self.ownerLogin = json["owner"]["login"].string
    self.ownerAvatarUrl = json["owner"]["avatar_url"].string
    self.url = json["url"].string
    
    self.files = [File]()
    if let filesJson = json["files"].dictionary {
      for (_, fileJson) in filesJson {
        if let newFile = File(fileJson) {
          self.files?.append(newFile)
        }
      }
    }
    //TODO: Dates
    let dateFormatter = Gist.sharedDateFormatter
    if let dateString = json["created_at"].string {
      self.created = dateFormatter.date(from: dateString)
    }
    if let dateString = json["updated_at"].string {
      self.updated = dateFormatter.date(from: dateString)
    }
  }
  
  required override init() {
    
  }
  
  static func dateFormatter() -> DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    return dateFormatter
  }
  
  //MARK: - NSCoding
  func encode(with aCoder: NSCoder) {
    aCoder.encode(id, forKey: "id")
    aCoder.encode(gistDescription, forKey: "gistDescription")
    aCoder.encode(ownerLogin, forKey: "ownerLogin")
    aCoder.encode(ownerAvatarUrl, forKey: "ownerAvatarUrl")
    aCoder.encode(url, forKey: "url")
    aCoder.encode(created, forKey: "created")
    aCoder.encode(updated, forKey: "updated")
    if let files = files {
      aCoder.encode(files, forKey: "files")
    }
  }
  
  required convenience init?(coder aDecoder: NSCoder) {
    self.init()
    id = aDecoder.decodeObject(forKey: "id") as? String
    gistDescription = aDecoder.decodeObject(forKey: "gistDescription") as? String
    ownerLogin = aDecoder.decodeObject(forKey: "ownerLogin") as? String
    ownerAvatarUrl = aDecoder.decodeObject(forKey: "ownerAvatarUrl") as? String
    url = aDecoder.decodeObject(forKey: "url") as? String
    created = aDecoder.decodeObject(forKey: "created") as? Date
    updated = aDecoder.decodeObject(forKey: "updated") as? Date
    if let files = aDecoder.decodeObject(forKey: "files") as? [File]{
      self.files = files
    }
  }
}
