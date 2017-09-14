//
//  Nanopass.swift
//  MothPackageDescription
//
//  Created by Andy Best on 14/09/2017.
//


import Foundation

class PassManager {
    var currentLanguage: Language!
    var languages: [Language]
    var passes: [Pass]
    
    init() {
        passes = []
        languages = []
    }
    
    func addLanguage(_ lang: Language) {
        currentLanguage = lang
        languages.append(lang)
    }
}

class Pass {
}

class Language {
    var terminalClauses: [String: TerminalClause]
    var clauses: [LanguageClause]
    var expressionTerminal: ExpressionTerminalClause
    
    init(terminalClauses: [String: TerminalClause], clauses: [String], passManager: PassManager) {
        self.terminalClauses = terminalClauses
        self.clauses = []
        self.expressionTerminal = ExpressionTerminalClause(passManager: passManager)
        
        // Parse clauses
        for c in clauses {
            do {
                let clause = try ClauseReader.read(c, passManager: passManager)
                self.clauses.append(clause)
            } catch {
                fatalError(String(describing: error))
            }
        }
    }
    
    func findTerminalClause(symbol: String) -> TerminalClause? {
        if symbol == "ε" {
            return expressionTerminal
        }
        
        return terminalClauses[symbol]
    }
    
    func formMatches(_ input: LispType) -> Bool {
        for c in clauses {
            if c.matches(input) {
                return true
            }
        }
        
        return false
    }
}
