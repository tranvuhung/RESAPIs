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
  
  case getPublic([String: AnyObject]?) // GET https://api.github.com/gists/public
  case getAtPath(String) // GET at given path
  case getMyStarred() // GET https://api.github.com/gists/starred
  case getMine() // GET https://api.github.com/gists
  case isStarred(String) // GET https://api.github.com/gists/\(gistId)/star
  case star(String) // PUT https://api.github.com/gists/\(gistId)/star
  case unstar(String) // DELETE https://api.github.com/gists/\(gistId)/star
  
  var method: HTTPMethod {
    switch self {
    case .getPublic:
      return .get
    case .getAtPath:
      return .get
    case .getMyStarred:
      return .get
    case .getMine:
      return .get
    case .isStarred:
      return .get
    case .star:
      return .put
    case .unstar:
      return .delete
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
      case .getMine:
        return ("/gists", nil)
      case .isStarred(let id):
        return ("/gists/\(id)/star", nil)
      case .star(let id):
        return ("/gists/\(id)/star", nil)
      case .unstar(let id):
        return ("/gists/\(id)/star", nil)
      }
    }()
    
    let url = try GistsRouter.baseURLString.asURL()
    var urlRequest = URLRequest(url: url.appendingPathComponent(result.path))
    urlRequest.httpMethod = method.rawValue
    
    // Set OAuth token if we have one
    if let token = GitHubAPIManager.sharedIntance.oauthToken{
      urlRequest.setValue("token \(token)", forHTTPHeaderField: "Authorization")
    }
    
    urlRequest = try URLEncoding.default.encode(urlRequest, with: result.parameters)
    
    return urlRequest
  }
}
