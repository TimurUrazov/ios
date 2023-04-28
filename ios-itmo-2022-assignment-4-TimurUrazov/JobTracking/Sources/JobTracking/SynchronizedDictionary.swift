//
//  File.swift
//  
//
//  Created by Timur Urazov on 21.12.2022.
//

import Foundation


class SynchronizedDictionary<Key: Hashable, Value> {
    private var dictionary: [Key: Value] = [:]
    private let queue = DispatchQueue(label: "JobTracker.SynchronizedDictionary", attributes: [.concurrent])

    var data: [Key: Value] {
        self.queue.sync {
            self.dictionary
        }
    }

    subscript(key: Key) -> Value? {
        get {
            self.queue.sync {
                self.dictionary[key]
            }
        }
        set {
            self.queue.async(flags: .barrier) {
                self.dictionary[key] = newValue
            }
        }
    }
    
    public func getAndBlock(key: Key, block: @escaping (Value) -> Void) {
        self.queue.async(flags: .barrier) {
            guard let value = self.dictionary[key] else {
                return
            }
            block(value)
        }
    }
    
    public func getAndSetAndBlock(key: Key, newValue: Value, block: @escaping (Value) -> Void) {
        self.queue.async(flags: .barrier) {
            guard let value = self.dictionary[key] else {
                return
            }
            self.dictionary[key] = newValue
            block(value)
        }
    }
}
