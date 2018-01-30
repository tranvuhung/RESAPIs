//
//  Gist.swift
//  GitHubGists
//
//  Created by Trần Vũ Hưng on 1/17/18.
//  Copyright © 2018 Tran Vu Hung. All rights reserved.
//

import Foundation
import SwiftyJSON

class Gist: ResponseJSONObjectSerializable {
  var id: String?
  var description: String?
  var ownerLogin: String?
  var ownerAvatarUrl: String?
  var url: String?
  var files:[File]?
  var created: Date?
  var updated: Date?
  
  static let sharedDateFormatter = Gist.dateFormatter()
  
  required init(_ json: JSON) {
    self.description = json["description"].string
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
  
  static func dateFormatter() -> DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    return dateFormatter
  }
}
