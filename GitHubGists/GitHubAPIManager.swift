//
//  GitHubAPIManager.swift
//  GitHubGists
//
//  Created by Trần Vũ Hưng on 1/17/18.
//  Copyright © 2018 Tran Vu Hung. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class GitHubAPIManager {
  static let sharedIntance = GitHubAPIManager()
  var sessionManager: Alamofire.SessionManager
  
  init() {
    let configuration = URLSessionConfiguration.default
    sessionManager = Alamofire.SessionManager(configuration: configuration)
  }
  
  func printPublicGists(){
    Alamofire.request(GistsRouter.getPublic(nil)).responseString { (response) in
      if let receivedString = response.result.value {
        print(receivedString)
      }
    }
  }
  
  func imageFormUrl(imageUrl: String, completionHandler: @escaping (UIImage?)-> ()) {
    sessionManager.request(imageUrl).response { (response) in
      guard let data = response.data else {return}
      let image = UIImage(data: data)
      completionHandler(image)
    }
  }
  
  //MARK: - Get gists and handler URLPage
  func getPublicGists(completionHandler: @escaping (Result<[Gist]>, String?) -> ()){
    sessionManager.request(GistsRouter.getPublic(nil)).validate().responseArray { (response: DataResponse<[Gist]>) in
      guard response.result.error == nil, let gists = response.result.value else {
        print(response.result.error!)
        completionHandler(response.result, nil)
        return
      }
      let next = self.getNextPage(response: response.response)
      completionHandler( .success(gists), next)
    }
  }
  
  func getPublicGists(urlPage: String?, completionHandler: @escaping (Result<[Gist]>, String?)->()){
    if let urlString = urlPage {
      getGists(urlRequest: GistsRouter.getAtPath(urlString), completionHandler: completionHandler)
    } else{
      getGists(urlRequest: GistsRouter.getPublic(nil), completionHandler: completionHandler)
    }
  }
  
  func getGists(urlRequest: URLRequestConvertible, completionHandler: @escaping (Result<[Gist]>, String?)->()){
    sessionManager.request(urlRequest).validate().responseArray { (response: DataResponse<[Gist]>) in
      guard response.result.error == nil, let gists = response.result.value else {
        print(response.result.error!)
        completionHandler(response.result, nil)
        return
      }
      let next = self.getNextPage(response: response.response)
      completionHandler( .success(gists), next)
    }
  }
  
  //MARK: - Get Url Page
  private func getNextPage(response: HTTPURLResponse?) -> String? {
    if let linkHeader = response?.allHeaderFields["Link"] as? String {
      print("LinkHeader: \(linkHeader)")
      let components = linkHeader.characters.split{$0 == ","}.map{ String($0)}
      
      for item in components {
        let rangeOfNext = item.range(of: "rel=\"next\"")
        if rangeOfNext != nil {
          let rangOfPaddedUrl = item.range(of: "<(.*)>;", options: .regularExpression)
          guard let range = rangOfPaddedUrl else {return nil}
          let nextUrl = item.substring(with: range)
          let startIndex = nextUrl.index(nextUrl.startIndex, offsetBy: 1)
          let endIndex = nextUrl.index(nextUrl.endIndex, offsetBy: -2)
          let urlRange = startIndex..<endIndex
          return nextUrl.substring(with: urlRange)
        }
      }
    }
    return nil
  }
}
