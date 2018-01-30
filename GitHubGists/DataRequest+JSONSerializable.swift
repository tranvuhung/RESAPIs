//
//  DataRequest+JSONSerializable.swift
//  GitHubGists
//
//  Created by Trần Vũ Hưng on 1/17/18.
//  Copyright © 2018 Tran Vu Hung. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

public protocol ResponseJSONObjectSerializable {
  init?(_ json: SwiftyJSON.JSON)
}

extension DataRequest {
  
  @discardableResult
  public func responseObject<T: ResponseJSONObjectSerializable>(completionHandler: @escaping (DataResponse<T>) -> ()) -> Self {
    let serializer = DataResponseSerializer<T> { (request, response, data, error) in
      
      guard error == nil else {return .failure(error!)}
      guard let responseData = data else {
        let error = AFError.responseSerializationFailed(reason: .inputDataNil)
        return .failure(error)
      }
      
      let jsonSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
      let result = jsonSerializer.serializeResponse(request, response, responseData, error)
      
      switch result {
      case .success(let value):
        let json = SwiftyJSON.JSON(value)
        if let object = T(json) {
          return .success(object)
        } else {
          let failureReason = "Object could not be created from JSON."
          print(failureReason)
          return .failure(error!)
        }
      case .failure(let error):
        return .failure(error)
      }
    }
    
    return response(responseSerializer: serializer, completionHandler: completionHandler)
  }
  
  @discardableResult
  public func responseArray<T: ResponseJSONObjectSerializable>(completionHandler: @escaping (DataResponse<[T]>) -> ()) -> Self {
    let serializer = DataResponseSerializer<[T]> { (request ,response, data, error) in
      
      guard error == nil else {return .failure(error!)}
      guard let responseData = data else {
        let error = AFError.responseSerializationFailed(reason: .inputDataNil)
        return .failure(error)
      }
      
      let jsonSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
      let result = jsonSerializer.serializeResponse(request, response, responseData, error)
      
      switch result {
      case .success(let value):
        let json = JSON(value)
        var objects: [T] = []
        for (_, item) in json {
          if let object = T(item) {
            objects.append(object)
          }
        }
        return .success(objects)
      case .failure(let error):
        return .failure(error)
      }
    }
    
    return response(responseSerializer: serializer, completionHandler: completionHandler)
  }
}
