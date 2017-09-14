//
//  Clauses.swift
//  MothPackageDescription
//
//  Created by Andy Best on 14/09/2017.
//

import Foundation

enum ClauseCaptureType {
    case one
    case zeroOrMore
    case oneOrMore
}

class LanguageClause {
    weak var passManager: PassManager!
    var captureType: ClauseCaptureType = .one
    
    init(passManager: PassManager) {
        self.passManager = passManager
    }
    
    func matches(_ input: LispType) -> Bool {
        return false
    }
    
    func debugDescription() -> String {
        return ""
    }
}

class ListClause: LanguageClause {
    let body: [LanguageClause]
    
    init(body: [LanguageClause], passManager: PassManager) {
        self.body = body
        super.init(passManager: passManager)
    }
    
    override func matches(_ input: LispType) -> Bool {
        switch input {
        case .list(let lst):
            var remaining = lst
            
            for clause in body {
                if remaining.count == 0 {
                    return false
                }
                
                if let groupClause = clause as? GroupClause {
                    if let r = groupClause.matchGroup(remaining) {
                        remaining = r
                    } else {
                        return false
                    }
                } else {
                    switch clause.captureType {
                    case .one:
                        if !clause.matches(remaining.first!) {
                            return false
                        }
                        
                        remaining = Array(remaining.dropFirst())
                        
                    case .oneOrMore:
                        var captured = 0
                        
                        // Capture until it doesn't match, or there is no input left
                        while remaining.count > 0 {
                            if !clause.matches(remaining.first!) {
                                break
                            }
                            
                            captured += 1
                            remaining = Array(remaining.dropFirst())
                        }
                        
                    case .zeroOrMore:
                        while remaining.count > 0 {
                            if !clause.matches(remaining.first!) {
                                break
                            }
                            
                            remaining = Array(remaining.dropFirst())
                        }
                    }
                }
            }
            
            // If there is any input remaining, it doesn't match.
            if remaining.count > 0 {
                return false
            }
            
            return true
            
        default: return false
        }
    }
    
    override func debugDescription() -> String {
        var desc = "(" + body.map { $0.debugDescription() }.joined(separator: " ") + ")"
        
        switch self.captureType {
        case .oneOrMore: desc += "+"
        case .zeroOrMore: desc += "*"
        default: break
        }
        
        return desc
    }
}

class GroupClause: LanguageClause {
    let body: [LanguageClause]
    
    init(body: [LanguageClause], passManager: PassManager) {
        self.body = body
        super.init(passManager: passManager)
    }
    
    override func matches(_ input: LispType) -> Bool {
        return false
    }
    
    func matchGroup(_ input: [LispType]) -> [LispType]? {
        var remaining = input
        var matchCount = 0
        
        while remaining.count >= body.count {
            var toMatch = remaining[0..<body.count]
            
            for i in 0..<body.count {
                if !body[i].matches(toMatch[i]) {
                    break
                }
            }
            
            matchCount += 1
            remaining = Array(remaining.dropFirst(body.count))
            
            if matchCount == 1 && captureType == .one {
                break
            }
        }
        
        switch captureType {
        case .one:
            if matchCount == 1 {
                return remaining
            } else {
                return nil
            }
            
        case .oneOrMore:
            if matchCount >= 1 {
                return remaining
            } else {
                return nil
            }
            
        case .zeroOrMore:
            return remaining
        }
        
    }
    
    override func debugDescription() -> String {
        var desc = "[" + body.map { $0.debugDescription() }.joined(separator: " ") + "]"
        
        switch self.captureType {
        case .oneOrMore: desc += "+"
        case .zeroOrMore: desc += "*"
        default: break
        }
        
        return desc
    }
}

class LiteralSymbolClause: LanguageClause {
    let symbolName: String
    
    init(symbolName: String, passManager: PassManager) {
        self.symbolName = symbolName
        super.init(passManager: passManager)
    }
    
    override func matches(_ input: LispType) -> Bool {
        switch input {
        case .symbol(let sym):
            return sym == symbolName
            
        default: return false
        }
    }
    
    override func debugDescription() -> String {
        return "'" + symbolName
    }
}

class TerminalSymbolClause: LanguageClause {
    let symbolName: String
    
    init(symbolName: String, passManager: PassManager) {
        self.symbolName = symbolName
        super.init(passManager: passManager)
    }
    
    override func matches(_ input: LispType) -> Bool {
        guard let clause = passManager.currentLanguage.findTerminalClause(symbol: symbolName) else {
            fatalError("Unknown terminal clause '\(symbolName)'")
        }
        
        return clause.matches(input)
    }
    
    override func debugDescription() -> String {
        return symbolName
    }
}
