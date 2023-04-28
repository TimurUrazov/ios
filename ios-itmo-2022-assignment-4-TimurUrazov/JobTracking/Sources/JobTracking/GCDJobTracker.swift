//
//  File.swift
//  
//
//  Created by Timur Urazov on 21.12.2022.
//

import Foundation

public class GCDJobTracker<Key: Hashable, Output, Failure: Error>: JobTracker<Key, Output, Failure>, CallbackJobTracking {
    private let taskQueue = DispatchQueue(label: "JobTracker.tasks")
    private let completionQueue = DispatchQueue(label: "JobTracker.completions", attributes: [.concurrent])
    
    var states = SynchronizedDictionary<Key, JobState>()
    
    public func startJob(for key: Key, completion: @escaping (Result<Output, Failure>) -> Void) {
        self.taskQueue.async {
            if (!self.memoizing.contains(.started) || self.states[key] == nil) {
                self.states[key] = .running(awaitingCallbacks: [])
                self.completionQueue.async {
                    self.worker(key) { result in
                        self.states.getAndSetAndBlock(key: key, newValue: .completed(result: result)) { state in
                            self.completionQueue.async {
                                completion(result)
                            }
                            switch(state) {
                            case .running(awaitingCallbacks: let awaitingCallbacks):
                                awaitingCallbacks.forEach { callback in
                                    self.completionQueue.async {
                                        callback(result)
                                    }
                                }
                            case .completed(result: _):
                                return
                            }
                        }
                    }
                }
            } else {
                if (self.memoizing.contains(.failed) || self.memoizing.contains(.succeeded)) {
                    self.states.getAndBlock(key: key) { state in
                        switch(state) {
                        case .running(awaitingCallbacks: var awaitingCallbacks):
                            awaitingCallbacks.append(completion)
                        case .completed(result: let result):
                            let success = self.checkResultIsSucessful(result: result)
                            if (self.memoizing.contains(.failed) && !success ||
                                self.memoizing.contains(.succeeded) && success) {
                                self.completionQueue.async {
                                    completion(result)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    public func checkResultIsSucessful(result: Result<Output, Failure>) -> Bool {
        switch result {
        case .success(_):
            return true
        case .failure(_):
            return false
        }
    }
    
    enum JobState {
        case running(awaitingCallbacks: [(Result<Output, Failure>) -> Void])
        case completed(result: Result<Output, Failure>)
    }
}
