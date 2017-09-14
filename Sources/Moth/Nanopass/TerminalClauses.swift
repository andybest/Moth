//
//  TerminalClauses.swift
//  MothPackageDescription
//
//  Created by Andy Best on 14/09/2017.
//

import Foundation

class TerminalClause {
    var passManager: PassManager!
    
    init(passManager: PassManager) {
        self.passManager = passManager
    }
    
    func matches(_ input: LispType) -> Bool {
        return false
    }
}

class VariableTerminalClause: TerminalClause {
    override func matches(_ input: LispType) -> Bool {
        switch input {
        case .symbol: return true
        default: return false
        }
    }
}

class PrimitiveTerminalClause: TerminalClause {
    override func matches(_ input: LispType) -> Bool {
        guard case let .symbol(sym) = input else {
            return false
        }
        
        // Is this a primitive function?
        
        let primitives: [String] = [
            "+", "-", "*", "/",
            "cons", "car", "cdr", "pair?",
            "vector", "make-vector", "vector-length",
            "vector-ref", "vector-set!", "vector?",
            "string", "make-string", "string-length",
            "string-ref", "string-set!", "string?",
            "void"
        ]
        
        return primitives.contains(sym)
    }
}

class DatumTerminalClause: TerminalClause {
    override func matches(_ input: LispType) -> Bool {
        return true
    }
}

class ConstantTerminalClause: TerminalClause {
    override func matches(_ input: LispType) -> Bool {
        switch input {
        case .number: return true
        case .string: return true
        case .boolean: return true
        default: return false
        }
    }
}


/// Matches any clause in the current language
class ExpressionTerminalClause: TerminalClause {
    override func matches(_ input: LispType) -> Bool {
        for clause in passManager.currentLanguage.clauses {
            if clause.matches(input) {
                return true
            }
        }
        
        return false
    }
}
