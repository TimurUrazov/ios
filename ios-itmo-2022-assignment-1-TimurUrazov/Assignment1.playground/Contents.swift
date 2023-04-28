import Foundation

/// Ассоциативность оператора
public enum Associativity {
    case left, right, none
}

public struct Operator<T: Numeric> {
    public let precedence: Int
    public let associativity: Associativity
    private let function: (T, T) throws -> T
    
    /// Конструктор с параметрами
    /// - Parameters:
    ///   - precedence: приоритет
    ///   - associativity: ассоциативность
    ///   - function: вычислимая бинарная функция
    public init(precedence: Int, associativity: Associativity, function: @escaping (T, T) -> T) {
        self.precedence = precedence
        self.associativity = associativity
        self.function = function
    }
    
    /// Применить оператор
    /// - Parameters:
    ///   - lhs: первый аргумент
    ///   - rhs: второй аргумент
    /// - Returns: результат, либо исключение
    public func apply(_ lhs: T, _ rhs: T) throws -> T {
        try self.function(lhs, rhs)
    }
}

/// Калькулятор
public protocol Calculator<Number> {
    /// Тип чисел, с которыми работает данный калькулятор
    associatedtype Number: Numeric
    
    init(operators: Dictionary<String, Operator<Number>>)
    
    func evaluate(_ input: String) throws -> Number
}

public enum CalculationError: Error {
    case ExcessiveArgumentError(String), NotEnoughArguementsError(String), ParsingError(String)
}

public protocol Negatible {
    mutating func negate()
}

extension Int: Negatible {}
extension Double: Negatible {}

public class AbstractCalculator<Number: Numeric & Negatible & LosslessStringConvertible> : Calculator {
    let inf = 100_000_000
    var operators: [String: Operator<Number>]
    
    public required init(operators: Dictionary<String, Operator<Number>>) {
        self.operators = operators
    }
    
    public func evaluate(_ input: String) throws -> Number {
        let functionStub = {
            (lhs: Number, _: Number) -> Number in
            return lhs
        }
        let bracketOperator = Operator(precedence: -inf, associativity: .none, function: functionStub)
        operators["("] = bracketOperator
        let negateOperator = Operator(precedence: inf, associativity: .none, function: functionStub)
        operators[")"] = bracketOperator
        
        var operandsStack: [Number] = []
        var operatorsStack: [Operator<Number>] = []
        var lastTokenIsOperand = false
        
        for token in input.components(separatedBy: .whitespaces) {
            if token == "-" && !lastTokenIsOperand {
                operatorsStack.append(negateOperator)
            } else if let currentOperator = operators[token] {
                try processOperator(
                    token: token,
                    currentOperator: currentOperator,
                    operandsStack: &operandsStack,
                    operatorsStack: &operatorsStack
                )
                lastTokenIsOperand = false
            } else if let value = Number(token) {
                operandsStack.append(value)
                lastTokenIsOperand = true
            } else {
                throw CalculationError.ParsingError("Can't parse token: \(token)...")
            }
        }
        
        try pickOperatorsFromStack(
            currentOperator: negateOperator, // just a stub
            operandsStack: &operandsStack,
            operatorsStack: &operatorsStack)
        
        guard operandsStack.count == 1 else {
            throw CalculationError.ExcessiveArgumentError("Excessive argument was passed to expression")
        }
        
        return operandsStack[0]
    }
    
    private func processOperator(
        token: String,
        currentOperator: Operator<Number>,
        operandsStack: inout [Number],
        operatorsStack: inout [Operator<Number>]
    ) throws {
        switch(token) {
        case "(":
            operatorsStack.append(currentOperator)
        case ")":
            try pickOperatorsFromStack(
                currentOperator: currentOperator,
                operandsStack: &operandsStack,
                operatorsStack: &operatorsStack,
                block: { $0.removeLast() },
                condition: {
                    _, operatorFromStack in
                    operatorFromStack.precedence != -inf
                }
            )
        default:
            try pickOperatorsFromStack(
                currentOperator: currentOperator,
                operandsStack: &operandsStack,
                operatorsStack: &operatorsStack,
                condition: {
                    currentOperator, operatorFromStack in
                    operatorFromStack.precedence > currentOperator.precedence
                    || operatorFromStack.precedence == currentOperator.precedence
                    && currentOperator.associativity != .right
                }
            )
            operatorsStack.append(currentOperator)
        }
    }
    
    private func pickOperatorsFromStack(
            currentOperator: Operator<Number>,
            operandsStack: inout [Number],
            operatorsStack: inout [Operator<Number>],
            block: (inout [Operator<Number>]) -> () = { _ in },
            condition: (Operator<Number>, Operator<Number>) -> Bool = {_, _ in return true}
    ) throws where Number: Numeric & Negatible {
            while !operatorsStack.isEmpty {
                if let stackOperator = operatorsStack.last {
                    if (stackOperator.precedence == inf) {
                        guard !operandsStack.isEmpty else {
                            throw CalculationError.NotEnoughArguementsError("Not enough arguments to apply to unary operator")
                        }
                        var next = operandsStack.removeLast()
                        next.negate()
                        operandsStack.append(next)
                    } else {
                        guard condition(currentOperator, stackOperator) else {
                            block(&operatorsStack)
                            break
                        }
                        guard operandsStack.count >= 2 else {
                            throw CalculationError.NotEnoughArguementsError("Not enough arguments to apply to binary operator")
                        }
                        let lastOperands = Array(operandsStack.suffix(2))
                        operandsStack.removeLast(2)
                        operandsStack.append(try stackOperator.apply(lastOperands[0], lastOperands[1]))
                    }
                    operatorsStack.removeLast()
                }
            }
        }
}

// Пример использования
func test(calculator type: (some Calculator<Int>).Type) {
    let calculator = type.init(operators: [
           "+": Operator(precedence: 10, associativity: .left, function: +),
           "-": Operator(precedence: 10, associativity: .left, function: -),
           "*": Operator(precedence: 20, associativity: .right, function: *),
           "/": Operator(precedence: 20, associativity: .left, function: /),
       ])
       
    assert(try! calculator.evaluate("1 + 5 * 3 + 4 / -2") == 14)
    assert(try! calculator.evaluate("5 * 4 / 2 * 2") == 5)
    assert(try! calculator.evaluate("( - 5 * - 4 / - 2 ) * - 2") == 20)
    assert(try! calculator.evaluate("- ( - 1 + - 2 ) * - 2") == -6)
    assert(try! calculator.evaluate("( - 1 + - 2 ) * - 2") == 6)
    assert(try! calculator.evaluate("- ( ( - ( - ( 1 ) ) + - ( - 2 ) ) ) * - 2") == 6)
    
    do {
        try calculator.evaluate("( - 1 + - 2 ) * -")
    } catch let calculationError as CalculationError {
        print ("CalculationError occured \(calculationError)")
    } catch {
        print(error)
    }
}

test(calculator: AbstractCalculator<Int>.self)
