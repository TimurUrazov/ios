//
//  File.swift
//  
//
//  Created by Timur Urazov on 22.12.2022.
//

import Foundation

class SimpleGCDJobTracker<T>: GCDJobTracker<Int, T, CalculationError> {}

class SimpleConcurrentJobTracker<T>: ConcurrentJobTrackerOldAPI<Int, T, CalculationError> {}

public enum CalculationError: Error {
    case ParsingError(Int)
}
