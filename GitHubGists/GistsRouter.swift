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
  case getMyStarred() // GET https://api.github.com/gists/starred
  
  var method: HTTPMethod {
    switch self {
    case .getPublic:
      return .get
    case .getAtPath:
      return .get
    case .getMyStarred:
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
      case .getMyStarred:
        return ("/gists/starred", nil)
      }
    }()
    
    let url = try GistsRouter.baseURLString.asURL()
    var urlRequest = URLRequest(url: url.appendingPathComponent(result.path))
    urlRequest.httpMethod = method.rawValue
    
    // Set OAuth token if we have one
    if let token = GitHubAPIManager.sharedIntance.OAuthToken{
      urlRequest.setValue("token \(token)", forHTTPHeaderField: "Authorization")
    }
    
    urlRequest = try URLEncoding.default.encode(urlRequest, with: result.parameters)
    
    return urlRequest
  }
}
