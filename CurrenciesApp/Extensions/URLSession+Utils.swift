//
//  URLSession+Utils.swift
//  CurrenciesApp
//
//  Created by Eduardo Carrero Yubero on 30/7/21.
//

import Foundation
import WebKit


enum URLResult {
    case response(Data, URLResponse)
    case error(Error, Data?, URLResponse?)
}

extension URLSession {
    @discardableResult
    func get(_ url: URL, completionHandler: @escaping (URLResult) -> Void) -> URLSessionDataTask {
        let task = dataTask(with: url) { data, response, error in
            switch (data, response, error) {
            case let (data, response, error?):
                completionHandler(.error(error, data, response))
            case let (data?, response?, nil):
                completionHandler(.response(data, response))
            default:
                preconditionFailure("expected either Data and URLResponse, or Error")
            }
        }
        task.resume()
        return task
    }
    
    @discardableResult
    func get(_ left: URL, _ right: URL, completionHandler: @escaping (URLResult, URLResult) -> Void) -> (URLSessionDataTask, URLSessionDataTask) {
        precondition(delegateQueue.maxConcurrentOperationCount == 1,
                     "URLSession's delegateQueue must be configured with a maxConcurrentOperationCount of 1.")
        
        var results: (left: URLResult?, right: URLResult?) = (nil, nil)
        
        func continuation() {
            guard case let (left?, right?) = results else { return }
            completionHandler(left, right)
        }
        
        let left = get(left) { result in
            results.left = result
            continuation()
        }
        
        let right = get(right) { result in
            results.right = result
            continuation()
        }
        
        return (left, right)
    }
}

extension URLResult {
    var string: String? {
        guard case let .response(data, _) = self,
              let string = String(data: data, encoding: .utf8)
        else { return nil }
        return string
    }
}
