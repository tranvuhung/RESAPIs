//
//  File.swift
//  GitHubGists
//
//  Created by Trần Vũ Hưng on 1/29/18.
//  Copyright © 2018 Tran Vu Hung. All rights reserved.
//

import Foundation
import SwiftyJSON

class File: ResponseJSONObjectSerializable {
  var filename: String?
  var raw_url: String?
  
  required init?(_ json: SwiftyJSON.JSON) {
    self.filename = json["filename"].string
    self.raw_url = json["raw_url"].string
  }
}
