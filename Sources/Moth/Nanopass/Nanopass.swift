//
//  Nanopass.swift
//  MothPackageDescription
//
//  Created by Andy Best on 14/09/2017.
//


import Foundation

typealias TransformFunc = (LispType) -> LispType

struct LanguageTransform {
    let addClauses: [String]
    let removeClauses: [String]
    let transformations: [String: TransformFunc]
}

class PassManager {
    var currentLanguage: Language!
    var languages: [Language]
    var passes: [Pass]
    
    init() {
        passes = []
        languages = []
    }
    
    func addPass(transform: LanguageTransform) {
        let oldLang = languages.last!
        let newLang = oldLang.createChild()
        
        for c in transform.removeClauses {
            newLang.removeClause(c)
        }
        
        for c in transform.addClauses {
            do {
                let clause = try ClauseReader.read(c, passManager: self)
                newLang.addClause(clause)
            } catch {
                print(error)
                fatalError("Unable to parse clause \(c)")
            }
        }
        
        let pass = Pass(fromLang: oldLang, toLang: newLang, transforms: transform.transformations)
        passes.append(pass)
    }
    
    func addLanguage(_ lang: Language) {
        currentLanguage = lang
        languages.append(lang)
    }
    
    func runPasses(_ input: LispType) -> LispType {
        var transformed = input
        
        for pass in passes {
            currentLanguage = pass.fromLang
            
            pass.fromLang.addTransforms(transforms: pass.transforms)
            
            // Validate input
            if !pass.fromLang.formMatches(transformed) {
                fatalError("Form does not match input!")
            }
            
            guard let c = pass.fromLang.matchingClause(transformed) else {
                fatalError("Cannot find matching clause for input!")
            }
            
            transformed = c.doTransform(transformed)
            
            pass.fromLang.clearAllTransforms()
        }
        
        return transformed
    }
}

class Pass {
    let fromLang: Language
    let toLang: Language
    let transforms: [String: TransformFunc]
    
    init(fromLang: Language, toLang: Language, transforms: [String: TransformFunc]) {
        self.fromLang = fromLang
        self.toLang = toLang
        self.transforms = transforms
    }
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
    
    init(other: Language) {
        self.terminalClauses = other.terminalClauses
        self.clauses = other.clauses
        self.expressionTerminal = other.expressionTerminal
    }
    
    func createChild() -> Language {
        return Language(other: self)
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
    
    func matchingClause(_ input: LispType) -> LanguageClause? {
        for c in clauses {
            if c.matches(input) {
                return c
            }
        }
        
        return nil
    }
    
    func addClause(_ clause: LanguageClause) {
        clauses.insert(clause, at: 0)
    }
    
    func removeClause(_ desc: String) {
        let clauseDescs = clauses.map { $0.debugDescription() }
        guard let clauseIdx = clauseDescs.index(of: desc) else {
            fatalError("Clause \"\(desc) not found in language!")
        }
        
        clauses.remove(at: clauseIdx)
    }
    
    func addTransforms(transforms: [String: TransformFunc]) {
        let clauseDescs = clauses.map { $0.debugDescription() }
        
        for t in transforms {
            guard let idx = clauseDescs.index(of: t.key) else {
                fatalError("Cannot find matching clause in language!")
            }
            
            clauses[idx].transform = t.value
        }
    }
    
    func clearAllTransforms() {
        for clause in clauses {
            clause.transform = nil
        }
    }
}
