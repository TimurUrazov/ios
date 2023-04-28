//
//  File.swift
//  
//
//  Created by Timur Urazov on 22.12.2022.
//

import Foundation
import Combine

public class CombineJobTracker<Key: Hashable, Output, Failure: Error>: JobTracker<Key, Output, Failure>, PublishingJobTracking {
    public typealias JobPublisher = AnyPublisher<Output, Failure>
    
    private let completionQueue = DispatchQueue(label: "JobTracker.completions", attributes: [.concurrent])
    private var publishers: Dictionary<Key, AnyPublisher<Output, Failure>> = [:]
    private var taskLock: NSLock = NSLock()
    
    public func startJob(for key: Key) -> AnyPublisher<Output, Failure> {
        taskLock.lock()
        defer {
            taskLock.unlock()
        }
        if (!self.memoizing.contains(.started)) {
            self.publishers.removeValue(forKey: key)
        }
        guard let publisher = publishers[key] else {
            let publisher = PassthroughSubject<Output, Failure>()
            defer {
                completionQueue.async {
                    self.worker(key) { res in
                        switch res {
                        case let .failure(error):
                            publisher.send(completion: .failure(error))
                        case let .success(success):
                            publisher.send(success)
                        }
                    }
                }
            }
            return publisher.eraseToAnyPublisher()
        }
        return publisher
    }
}
