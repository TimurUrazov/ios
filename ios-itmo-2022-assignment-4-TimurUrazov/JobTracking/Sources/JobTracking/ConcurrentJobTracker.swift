//
//  File.swift
//  
//
//  Created by Timur Urazov on 22.12.2022.
//

import Foundation

public class ConcurrentJobTrackerOldAPI<Key: Hashable, Output, Failure: Error>: GCDJobTracker<Key, Output, Failure>, AsyncJobTracking {
    public func startJob(for key: Key) async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            super.startJob(for: key, completion: continuation.resume(with:))
        }
    }
}

actor JobActor<Key: Hashable, Output, Failure: Error> {
    public func doJob(block: () async throws -> Output) async throws -> Output {
        try await block()
    }
}

public class ConcurrentJobTracker<Key: Hashable, Output, Failure: Error>: JobTracker<Key, Output, Failure>, AsyncJobTracking {
    var tasks = Dictionary<Key, Task<Output, Error>>()
    var jobActor = JobActor<Key, Output, Failure>()
    
    public func startJob(for key: Key) async throws -> Output {
        try await jobActor.doJob {
            if (!self.memoizing.contains(.started)) {
                self.tasks.removeValue(forKey: key)
            }
            guard let state = self.tasks[key] else {
                let task = Task {
                    try await withCheckedThrowingContinuation { continuation in
                        self.worker(key) { result in
                            switch result {
                            case let .success(output):
                                continuation.resume(returning: output)
                            case let .failure(err):
                                continuation.resume(throwing: err)
                            }
                        }
                    }
                }
                self.tasks[key] = task
                return try await task.value
            }
            do {
                let success = try await state.value
                if (self.memoizing.contains(.succeeded)) {
                    return success
                }
            } catch let failure as Failure {
                if (self.memoizing.contains(.failed)) {
                    throw failure
                }
            }
            throw CustomError.taskIsDuplicatedError("Task is duplicated.")
        }
    }
    
    enum CustomError: Error {
        case stateIsAbsentError(String)
        case taskIsDuplicatedError(String)
    }
}
