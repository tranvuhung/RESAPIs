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
  
  required init(json: JSON) {
    self.description = json["description"].string
    self.id = json["id"].string
    self.ownerLogin = json["owner"]["login"].string
    self.ownerAvatarUrl = json["owner"]["avatar_url"].string
    self.url = json["url"].string
  }
  
  required init() {
    
  }
}
