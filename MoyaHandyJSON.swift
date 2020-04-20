//
//  MoyaResponseHandyJSON.swift
//  HJSwift
//
//  Created by PAN on 2017/10/24.
//  Copyright © 2017年 YR. All rights reserved.
//

import Foundation
import HandyJSON
import Moya
import RxSwift

public enum HandyJSONMapError: Error, LocalizedError {
    case mapError(String)

    public var errorDescription: String? {
        if case let .mapError(json) = self {
            #if DEBUG
                return "Failed to map to HandyJSON object. \(json)"
            #else
                return nil
            #endif
        }
        return nil
    }
}

private func DebugPrint(_ json: Any?, file: String = #file, method: String = #function, line: Int = #line) {
    let env = "🔺DEBUGJSON: \((file as NSString).lastPathComponent)[\(line)], \(method)🔺" as Any
    let strs = ([env] + (json != nil ? [json!] : [])).map { "\($0)" }.joined(separator: " ")
    print(strs)
}

public extension Response {
    func map<D: HandyJSON>(_ type: D.Type, atKeyPath keyPath: String? = nil) throws -> D {
        let jsonString = try mapString()
        if let obj = D.deserialize(from: jsonString, designatedPath: keyPath) {
            return obj
        }
        throw HandyJSONMapError.mapError(jsonString)
    }

    func map<D: HandyJSON>(_ type: [D].Type, atKeyPath keyPath: String? = nil) throws -> [D] {
        let jsonString = try mapString()
        if let objs = [D].deserialize(from: jsonString, designatedPath: keyPath) as? [D] {
            return objs
        }
        throw HandyJSONMapError.mapError(jsonString)
    }
}

public extension PrimitiveSequence where Trait == SingleTrait, Element == Response {
    func map<D: HandyJSON>(_ type: D.Type, atKeyPath keyPath: String? = nil) -> Single<D> {
        return
            observeOn(SerialDispatchQueueScheduler(qos: .default))
            .flatMap { response -> Single<D> in
                Single.just(try response.map(type, atKeyPath: keyPath))
            }.observeOn(MainScheduler.instance)
    }

    func map<D: HandyJSON>(_ type: [D].Type, atKeyPath keyPath: String? = nil) -> Single<[D]> {
        return
            observeOn(SerialDispatchQueueScheduler(qos: .default))
            .flatMap { response -> Single<[D]> in
                Single.just(try response.map(type, atKeyPath: keyPath))
            }.observeOn(MainScheduler.instance)
    }

    func debugJSON(file: String = #file, method: String = #function, line: Int = #line) -> Single<Response> {
        #if DEBUG
            return flatMap { response -> Single<Response> in
                let json = try? response.mapJSON()
                DebugPrint(json, file: file, method: method, line: line)
                return Single.just(response)
            }
        #else
            return self
        #endif
    }
}

public extension PrimitiveSequence where Trait == SingleTrait, Element: HandyJSON {
    func debugJSON(file: String = #file, method: String = #function, line: Int = #line) -> Single<Element> {
        #if DEBUG
            return flatMap { object -> Single<Element> in
                let json = object.toJSON() ?? [:]
                DebugPrint(json, file: file, method: method, line: line)
                return Single.just(object)
            }
        #else
            return self
        #endif
    }
}

public extension ObservableType where Element == Response {
    func map<D: HandyJSON>(_ type: D.Type, atKeyPath keyPath: String? = nil) -> Observable<D> {
        return
            observeOn(SerialDispatchQueueScheduler(qos: .default))
            .flatMap { response -> Observable<D> in
                Observable.just(try response.map(type, atKeyPath: keyPath))
            }.observeOn(MainScheduler.instance)
    }

    func map<D: HandyJSON>(_ type: [D].Type, atKeyPath keyPath: String? = nil) -> Observable<[D]> {
        return
            observeOn(SerialDispatchQueueScheduler(qos: .default))
            .flatMap { response -> Observable<[D]> in
                Observable.just(try response.map(type, atKeyPath: keyPath))
            }.observeOn(MainScheduler.instance)
    }

    func debugJSON(file: String = #file, method: String = #function, line: Int = #line) -> Observable<Response> {
        #if DEBUG
            return flatMap { response -> Observable<Response> in
                let json = try? response.mapJSON()
                DebugPrint(json, file: file, method: method, line: line)
                return Observable.just(response)
            }
        #else
            return asObservable()
        #endif
    }
}

public extension ObservableType where Element: HandyJSON {
    func debugJSON(file: String = #file, method: String = #function, line: Int = #line) -> Observable<Element> {
        #if DEBUG
            return flatMap { object -> Observable<Element> in
                let json = object.toJSON() ?? [:]
                DebugPrint(json, file: file, method: method, line: line)
                return Observable.just(object)
            }
        #else
            return asObservable()
        #endif
    }
}
