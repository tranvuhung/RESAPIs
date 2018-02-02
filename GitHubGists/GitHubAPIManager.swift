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
import Locksmith

class GitHubAPIManager {
  //MARK: - Properties
  static let sharedIntance = GitHubAPIManager()
  var sessionManager: Alamofire.SessionManager
  static let ErrorDomain = "com.error.GitHubAPIManager"
  
  init() {
    let configuration = URLSessionConfiguration.default
    sessionManager = Alamofire.SessionManager(configuration: configuration)
  }
  
  let clientID: String = "abe56aee857975a84cad"
  let clientSecret: String = "13e437255b0b0714384a672dced18d034f4c6c50"
  
  var oauthToken: String? {
    set {
      guard let value = newValue else {
        let _ = try? Locksmith.deleteDataForUserAccount(userAccount: "github")
        return
      }
      
      do {
        try Locksmith.updateData(data: ["token": value], forUserAccount: "github")
      } catch{
        let _ = try? Locksmith.deleteDataForUserAccount(userAccount: "github")
      }
    }
    
    get {
      // try to load from keychain
      let dictionary = Locksmith.loadDataForUserAccount(userAccount: "github")
      if let token = dictionary?["token"] as? String {
        return token
      }
      return nil
    }
  }
  
  var oauthTokenCompletionHandler: ((NSError?) -> ())?
  
  //MARK: - Load avartar image
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
  
  func getPublicGists(_ urlPage: String?, completionHandler: @escaping (Result<[Gist]>, String?)->()){
    if let urlString = urlPage {
      getGists(urlRequest: GistsRouter.getAtPath(urlString), completionHandler: completionHandler)
    } else{
      getGists(urlRequest: GistsRouter.getPublic(nil), completionHandler: completionHandler)
    }
  }
  
  func getGists(urlRequest: URLRequestConvertible, completionHandler: @escaping (Result<[Gist]>, String?)->()){
    sessionManager.request(urlRequest).validate().responseArray { (response: DataResponse<[Gist]>) in
      if let urlResponse = response.response, let authError = self.checkUnauthorized(urlResponse) {
        completionHandler(.failure(authError), nil)
        return
      }
      guard response.result.error == nil, let gists = response.result.value else {
        print(response.result.error!)
        completionHandler(response.result, nil)
        return
      }
      let next = self.getNextPage(response: response.response)
      completionHandler( .success(gists), next)
    }
  }
  
  func getMyStarredGists(_ urlPage: String?, completionHandler: @escaping (Result<[Gist]>, String?)-> ()){
    if let urlString = urlPage {
      getGists(urlRequest: GistsRouter.getAtPath(urlString), completionHandler: completionHandler)
    } else {
      getGists(urlRequest: GistsRouter.getMyStarred(), completionHandler: completionHandler)
    }
  }
  
  func getMyGists(_ urlPage: String?, completionHandler: @escaping (Result<[Gist]>, String?) -> ()){
    if let urlString = urlPage {
      getGists(urlRequest: GistsRouter.getAtPath(urlString), completionHandler: completionHandler)
    } else {
      getGists(urlRequest: GistsRouter.getMine(), completionHandler: completionHandler)
    }
  }
  
  // MARK: Starring / Unstarring / Star status
  func isGistStarred(gistId: String, completionHandler: @escaping (Result<Bool>)->()){
    // GET /gists/:id/star
    sessionManager.request(GistsRouter.isStarred(gistId)).validate(statusCode: [204]).response { (dataResponse) in
      if let urlResponse = dataResponse.response, let authError = self.checkUnauthorized(urlResponse) {
        completionHandler(.failure(authError))
        return
      }
      // 204 if starred, 404 if not
      if let error = dataResponse.error {
        print(error)
        if dataResponse.response?.statusCode == 404 {
          completionHandler(.success(false))
          return
        }
        completionHandler(.failure(error))
        return
      }
      completionHandler(.success(true))
    }
  }
  
  func starGist(gistId: String, completionHandler: @escaping (Error?) -> ()){
    sessionManager.request(GistsRouter.star(gistId)).response { (dataResponse) in
      if let urlResponse = dataResponse.response, let authError = self.checkUnauthorized(urlResponse) {
        completionHandler(authError)
        return
      }
      if let error = dataResponse.error {
        print(error)
        return
      }
      completionHandler(dataResponse.error)
    }
  }
  
  func unstarGist(gistId: String, completionHandler: @escaping (Error?) -> ()){
    sessionManager.request(GistsRouter.unstar(gistId)).response { (dataResponse) in
      if let urlResponse = dataResponse.response, let authError = self.checkUnauthorized(urlResponse) {
        completionHandler(authError)
        return
      }
      if let error = dataResponse.error {
        print(error)
        return
      }
      completionHandler(dataResponse.error)
    }
  }
  
  //MARK: - Delete gist
  func deleteGist(gistId: String, completionHandler: @escaping (Error?) -> ()){
    sessionManager.request(GistsRouter.delete(gistId)).response { (dataResponse) in
      if let urlResponse = dataResponse.response, let authError = self.checkUnauthorized(urlResponse) {
        completionHandler(authError)
        return
      }
      if let error = dataResponse.error{
        print(error)
        return
      }
      completionHandler(dataResponse.error)
    }
  }
  
  //MARK: - Create gist
  func createNewGist(description: String, isPublic: Bool, files: [File], completionHandler: @escaping (Result<Bool>) -> ()){
    
    let publicString: String
    if isPublic{
      publicString = "true"
    } else {
      publicString = "false"
    }
    var filesDictionary = [String: Any]()
    for file in files {
      if let name = file.filename, let content = file.content {
        filesDictionary[name] = ["content": content]
      }
    }
    
    let parameters: [String: Any] = ["description": description, "public": publicString, "files": filesDictionary]
    
    sessionManager.request(GistsRouter.create(parameters))
      .validate { request, response, data in
        guard data != nil else {
          let error = NSError(domain: GitHubAPIManager.ErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "We didn't get any data", NSLocalizedRecoverySuggestionErrorKey: "Please retry your request"])
          return .failure(error)
        }
        if let authError = self.checkUnauthorized(response) {
          completionHandler(.failure(authError))
        }
        return .success
      }
      .response { (dataResponse) in
        if let error = dataResponse.error {
          print(error)
          completionHandler(.success(false))
          return
        }
        self.clearCache()
        completionHandler(.success(true))
    }
  }
  
  //MARK: - Get Url Page
  private func getNextPage(response: HTTPURLResponse?) -> String? {
    if let linkHeader = response?.allHeaderFields["Link"] as? String {
      //print("LinkHeader: \(linkHeader)")
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
  
  //MARK: - Basic Auth
  func printMyStarredGists(){
    //TODO: - Implement
    Alamofire.request(GistsRouter.getMyStarred()).responseString { (response) in
      if let receivedString = response.result.value {
        print(receivedString)
      }
    }
  }
  
  func doBasicAuthCredential(){
    let username = "tranvuhung"
    let password = "danden06"
    
    let credential = URLCredential(user: username, password: password, persistence: URLCredential.Persistence.forSession)
    
    Alamofire.request("https://httpbin.org/basic-auth/\(username)/\(password)", method: .get).authenticate(usingCredential: credential).response {
      response in
      if let received = response.data {
        print(received)
      }
    }
  }
  
  //MARK: - Auth 2.0 flow
  func printMyStarredWithAuth(){
    let starredGistRequest = Alamofire.request(GistsRouter.getMyStarred()).responseString { (response) in
      guard response.result.error == nil else {
        print(response.result.error!)
        GitHubAPIManager.sharedIntance.oauthToken = nil
        return
      }
      if let receivedString = response.result.value {
        print(receivedString)
      }
    }
    debugPrint(starredGistRequest)
  }
  
  func hasAuthToken() -> Bool {
    //TODO: - implement
    if let token = oauthToken{
      return !token.isEmpty
    }
    return false
  }
  
  func urlToStartAuth2Login() -> URL? {
    let authPath = "https://github.com/login/oauth/authorize?client_id=\(clientID)&scope=gist&state=TEST_STATE"
    guard let authUrl: URL = URL(string: authPath) else {
      // TODO: handle error
      return nil
    }
    return authUrl
  }
  
  func processOAuthStep1Response(url: URL){
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    var code: String?
    guard let queryItems = components?.queryItems else {return}
    for queryItem in queryItems {
      if queryItem.name.lowercased() == "code"{
        code = queryItem.value
        break
      }
    }
    if let receivedCode = code  {
      // no code in URL that we launched with
      swapAuthCodeForToken(receivedCode)
    } else {
      let defaults = UserDefaults.standard
      defaults.set(false, forKey: "loadingOAuthToken")
      if let completionHanlder = oauthTokenCompletionHandler {
        let noCodeInResponseError = NSError(domain: GitHubAPIManager.ErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not obtain an OAuth code", NSLocalizedRecoverySuggestionErrorKey: "Please retry your request"])
        completionHanlder(noCodeInResponseError)
      }
    }
  }
  
  func swapAuthCodeForToken(_ receivedCode: String){
    let getTokenPath = "https://github.com/login/oauth/access_token"
    let tokenParams = ["client_id": clientID, "client_secret": clientSecret, "code": receivedCode]
    let header = ["Accept": "application/json"]
    Alamofire.request(getTokenPath, method: .post, parameters: tokenParams, headers: header).responseString { (response) in
      // TODO: handle response to extract OAuth token
      if let error = response.result.error {
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: "loadingOAuthToken")
        // TODO: bubble up error
        if let completionHandler = self.oauthTokenCompletionHandler {
          completionHandler(error as NSError)
        }
        return
      }
      print(response.result.value!)
      guard let receivedResult = response.result.value, let jsonData = receivedResult.data(using: String.Encoding.utf8, allowLossyConversion: false) else {return}
      let jsonResult = JSON(jsonData)
      for (key, value) in jsonResult{
        switch key {
        case "access_token":
          self.oauthToken = value.string
        case "scope":
          // TODO: verify scope
          print("SET SCOPE")
        case "token_type":
          // TODO: verify is bearer
          print("CHECK IF BEARER")
        default:
          print("got more than I expected from the OAuth token exchange")
          print(key)
        }
      }
      
      let defaults = UserDefaults.standard
      defaults.set(false, forKey: "loadingOAuthToken")
      
      if let completionHandler = self.oauthTokenCompletionHandler {
        if self.hasAuthToken(){
          completionHandler(nil)
        } else {
          let noOAuthError = NSError(domain: GitHubAPIManager.ErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not obtain an OAuth token", NSLocalizedRecoverySuggestionErrorKey: "Please retry your request"])
          completionHandler(noOAuthError)
        }
      }
      
      if self.hasAuthToken(){
        self.printMyStarredWithAuth()
      }
    }
  }
  
  //MARK: - Check Unauthorized
  func checkUnauthorized(_ urlResponse: HTTPURLResponse) -> NSError? {
    if urlResponse.statusCode == 401 {
      oauthToken = nil
      let lostOAuth = NSError(domain: GitHubAPIManager.ErrorDomain, code: NSURLErrorUserAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: "Not Logged in", NSLocalizedRecoverySuggestionErrorKey: "Please re-enter your GitHub credentials"])
      return lostOAuth
    }
    return nil
  }
  
  //MARK: - Clear Cache
  func clearCache() {
    let cache = URLCache.shared
    cache.removeAllCachedResponses()
  }
}
