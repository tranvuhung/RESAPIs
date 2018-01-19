//
//  GistsRouter.swift
//  GitHubGists
//
//  Created by Trần Vũ Hưng on 1/17/18.
//  Copyright © 2018 Tran Vu Hung. All rights reserved.
//

import Foundation
import Alamofire

enum GistsRouter: URLRequestConvertible {
  static let baseURLString:String = "https://api.github.com"
  
  case getPublic([String: AnyObject]?)
  case getAtPath(String)
  
  var method: HTTPMethod {
    switch self {
    case .getPublic:
      return .get
    case .getAtPath:
      return .get
    }
  }
  
  func asURLRequest() throws -> URLRequest {
    
    let result: (path: String, parameters: [String: AnyObject]?) = {
      switch self {
      case .getPublic:
        return ("/gists/public", nil)
      case .getAtPath(let path):
        let URL = NSURL(string: path)
        let relativePath = URL!.relativePath!
        return (relativePath, nil)
      }
    }()
    
    let url = try GistsRouter.baseURLString.asURL()
    var urlRequest = URLRequest(url: url.appendingPathComponent(result.path))
    urlRequest.httpMethod = method.rawValue
    urlRequest = try URLEncoding.default.encode(urlRequest, with: result.parameters)
    
    return urlRequest
  }
}
