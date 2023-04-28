//
//  File.swift
//  
//
//  Created by Timur Urazov on 21.12.2022.
//

import Foundation

class AtomicInt {
    private var queue = DispatchQueue(label: "JobTraker.AtomicInt")
    private var _value = 0

    public var value: Int {
        get {
            self.queue.sync {
                self._value
            }
        }
    }

    func getAndIncrement() -> Int {
        self.queue.sync {
            let previousValue = self._value
            self._value += 1
            return previousValue
        }
    }

    func getAndDecrement() -> Int {
        self.queue.sync {
            let previousValue = self._value
            self._value -= 1
            return previousValue
        }
    }
}

extension AtomicInt: Hashable {
    static func == (lhs: AtomicInt, rhs: AtomicInt) -> Bool {
        lhs.queue.sync {
            lhs._value == rhs.value
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(_value)
    }
}
