//
//  DYMRequestManager.swift
//  DingYueMobileSDK
//
//  Created by 靖核 on 2022/4/4.
//

import UIKit

enum DYMHttpMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}

typealias DYMResponseCompletion<T: DYMJSONCodable> = (Result<T,DYMError>,HTTPURLResponse?) -> Void

private class DYMSessionTask: Equatable {
    
    var task: URLSessionDataTask?
    var router: DYMRouter?
    var retryTimes: Int = 0
    var maxTryTimes: Int = 3
    var retryDelay: TimeInterval = 2
    
    init(task: URLSessionDataTask? = nil, router: DYMRouter?, maxRetryTimes: Int = 3, retryDelay: TimeInterval = 2) {
        self.task = task
        self.router = router
        self.maxTryTimes = maxRetryTimes
        self.retryDelay = retryDelay
    }
    
    func retry(completion:@escaping (Data?,URLResponse?,Error?) -> Void) {
        retryTimes += 1
        if retryTimes >= maxTryTimes {
            completion(nil,nil,DYMError.badRequest)
            return
        }
        guard let request = task?.originalRequest else {
            completion(nil,nil,DYMError.badRequest)
            return
        }
        task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            DispatchQueue.global(qos: .background).async {
                completion(data, response, error)
            }
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
            self.resume()
        }
    }
    
    @objc func resume() {
        guard let task = task else { return }
        task.resume()
    }
    
    static func == (lhs: DYMSessionTask, rhs: DYMSessionTask) -> Bool {
        if lhs.task != rhs.task { return false }
        if lhs.retryTimes != rhs.retryTimes { return false }
        if lhs.maxTryTimes != rhs.maxTryTimes { return false }
        if lhs.retryDelay != rhs.retryDelay { return false }
        return true
    }
}

class DYMRequestManager {
    
    static let shared = DYMRequestManager()
    
    private var runningLimit: Int { 1 }
    private var waitingTasks: [DYMSessionTask] = [] {
        didSet {
            startRequestIfPossible()
        }
    }
    private var runningTasks: [DYMSessionTask] = []
    private var concurrentQueue = DispatchQueue(label: "com.dingyuemobile.concurrentQueue", attributes: .concurrent)
    
    @discardableResult
    class func request<T: DYMJSONCodable>(router: DYMRouter, completion: @escaping DYMResponseCompletion<T>) -> URLSessionDataTask? {
        do {
            let request = try router.configURLRequest()
            return shared.request(request, router: router, completion: completion)
        } catch let error as DYMError {
            DYMLogManager.logError(error)
            completion(.failure(error),nil)
        } catch {
            DYMLogManager.logError(error)
            completion(.failure(DYMError(error)),nil)
        }
        return nil
    }
    
    @discardableResult
    class func request<T: DYMJSONCodable>(_ request: URLRequest, router: DYMRouter?, completion: @escaping DYMResponseCompletion<T>) -> URLSessionDataTask? {
        shared.request(request, router: router, completion: completion)
    }
    
    @discardableResult
    private func request<T: DYMJSONCodable>(_ request: URLRequest, router: DYMRouter?, completion: @escaping DYMResponseCompletion<T>) -> URLSessionDataTask? {
        let task = DYMSessionTask(router: router)
        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.global(qos: .background).async {
                self.handleResponse(task: task, data: data, response: response, error: error) { (result: Result<T,DYMError>, response) in
                    switch result {
                    case .failure(let failure):
                        if failure.dymCode == .missingParam {
                            
                        }else {
                            DYMLogManager.logError(failure)
                        }
                    default: break
                    }
                    completion(result,response)
                }
            }
        }
        task.task = dataTask
        concurrentQueue.async(flags: .barrier) { self.waitingTasks.append(task)}
        return dataTask
    }
    
    private func startRequestIfPossible() {
        guard let task = waitingTasks.first, runningTasks.count < runningLimit else { return }
        runningTasks.append(task)
        waitingTasks.removeFirst()
        task.resume()
    }
    
    private func handleResponse<T: DYMJSONCodable>(task: DYMSessionTask, data: Data?, response: URLResponse?, error: Error?, completion: @escaping DYMResponseCompletion<T>) {
        logResponse(data, response, task)
        
        if let error = error as NSError? {
            //如果是网络问题直接重新请求
            if error.isNotConnection {
                task.retry(completion: { data, response, error in
                    self.handleResponse(task: task, data: data, response: response, error: error, completion: completion)
                })
            } else {//处理失败结果
                handleResult(task: task, result: .failure(DYMError(error)), response: nil, completion: completion)
            }
            return
        }
        //判断是否有请求答复
        guard let response = response as? HTTPURLResponse else {
            handleResult(task: task, result: .failure(DYMError.emptyResponse), response: nil, completion: completion)
            return
        }
        //判断是否返回数据
        guard let data = data else {
            handleResult(task: task, result: .failure(DYMError.emptyData), response: response, completion: completion)
            return
        }
        //判断是否为服务器问题，如果是则重新请求
        if handleNetwork(status: response.statusCode)?.dymCode == .server {
            task.retry(completion: { data, response, error in
                self.handleResponse(task: task, data: data, response: response, error: error, completion: completion)
            })
            return
        }
        //解析返回json
        guard let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? DYMParams else {
            handleResult(task: task, result: .failure(DYMError.unableToDecode), response: nil, completion: completion)
            return
        }
        
        if let error = self.handleNetwork(status: response.statusCode) {
            do {
                let responseErrors = try DYMResponseErrors(json: json)
                if let responseError = responseErrors?.errors.first {
                    handleResult(task: task, result: .failure(DYMError(code: responseError.status, dymCode: error.dymCode, message: responseError.description)), response: nil, completion: completion)
                    return
                }
                
                handleResult(task: task, result: .failure(error), response: response, completion: completion)
                return
            } catch let error as DYMError {
                handleResult(task: task, result: .failure(error), response: response, completion: completion)
                return
            } catch {
                handleResult(task: task, result: .failure(DYMError(error)), response: response, completion: completion)
                return
            }
        }
        
        if let responseObject = try? T(json: json) {
            handleResult(task: task, result: .success(responseObject!), response: response, completion: completion)
        } else {
            handleResult(task: task, result: .failure(DYMError.unableToDecode), response: response, completion: completion)
        }
    }
    
    private func handleResult<T: DYMJSONCodable>(task: DYMSessionTask, result: Result<T, DYMError>, response: HTTPURLResponse?, completion: @escaping DYMResponseCompletion<T>) {
        
        func removeCurrentTask() {
            runningTasks.removeAll { $0 == task }
        }
        
        func startNextTask() {
            removeCurrentTask()
            startRequestIfPossible()
        }
        
        if case .session = task.router,
           case .failure = result,
           let request = task.task?.originalRequest {
            
            self.request(request, router: task.router, completion: completion)
            
            concurrentQueue.async(flags: .barrier) {
                if self.waitingTasks.count == 1 {
                    // don't need to start cycling request, so don't start next create profile request
                    removeCurrentTask()
                } else {
                    // regular logic
                    startNextTask()
                }
            }
            return
        }
        
        DispatchQueue.main.async {
            switch result {
            case .success(let result):
                completion(.success(result), response)
            case .failure(let error):
                completion(.failure(error), response)
            }
        }
        
        concurrentQueue.async(flags: .barrier) {
            startNextTask()
        }
    }
    
    private func handleNetwork(status code: Int) -> DYMError? {
        switch code {
        case 200...299: return nil
        case 401, 403: return DYMError.authenticate
        case 429, 500...599: return DYMError.server
        case 400...499: return DYMError.badRequest
        default: return DYMError.failed
        }
    }
    
    private func logResponse(_ data: Data?, _ response: URLResponse?, _ task: DYMSessionTask) {
        var message = "Received response: \(response?.url?.absoluteString ?? "")\n"
        if let data = data, let jsonString = String(data: data, encoding: .utf8) {
            message.append("\(jsonString)\n")
        }
        if let response = response as? HTTPURLResponse {
            message.append("Headers: \(response.allHeaderFields)")
        }
        switch task.router {
        case .trackEvent:
            DYMLogManager.logGlobalMessage(message)
        default:
            DYMLogManager.logMessage(message)
        }
    }
    
}
