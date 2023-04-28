//
//  File.swift
//  
//
//  Created by Timur Urazov on 21.12.2022.
//

import Foundation

public class JobTracker<Key: Hashable, Output, Failure: Error>: JobTracking {
    public typealias Key = Key
    public typealias Output = Output
    public typealias Failure = Failure
    
    let memoizing: MemoizationOptions
    let worker: JobWorker<Key, Output, Failure>
    
    public required init(memoizing: MemoizationOptions, worker: @escaping JobWorker<Key, Output, Failure>) {
        self.memoizing = memoizing
        self.worker = worker
    }
}
