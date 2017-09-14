//
//  Compiler.swift
//  MothPackageDescription
//
//  Created by Andy Best on 14/09/2017.
//

import Foundation

class Compiler {
    let passManager = PassManager()
    
    init() {
        let initialLang = Language(terminalClauses: [
            "s": VariableTerminalClause(passManager: passManager),
            "pr": PrimitiveTerminalClause(passManager: passManager),
            "c": ConstantTerminalClause(passManager: passManager),
            "d": DatumTerminalClause(passManager: passManager)
            ],
                                   clauses: [
                                    "pr",
                                    "s",
                                    "c",
                                    "('if ε ε)",        // One armed if
                                    "('if ε ε ε)",      // Two armed if
                                    "('or ε ε+)",
                                    "('and ε ε+)",
                                    "('not ε)",
                                    "('do ε+)",
                                    "('let ([s ε]+) ε+)",    // Let form
                                    "('fn ([s*]) ε+)",       // Function form
                                    "(ε+)",                   // Apply form, e.g. (x 1 2 3)
                                    "(s+)"
            ],
                                   passManager: passManager)
        
        passManager.languages.append(initialLang)
        
        addPasses()
    }
    
    func compile(input: LispType) -> LispType {
        let transformed = passManager.runPasses(input)
        return transformed
    }
    
    func addPasses() {
        addRemoveOneArmedIfPass()
        addExplicitDoInLetBodyPass()
        addExplicitDoInFunctionBodyPass()
    }
    
    func addRemoveOneArmedIfPass() {
        let t = LanguageTransform(addClauses: [],
                                   removeClauses: [
                                    "('if ε ε)"
            ],
                                   transformations: [
                                    "('if ε ε)": { input in
                                        // Remove one armed if and replace with a 2 armed if with the else branch returning nil.
                                        guard case let .list(lst) = input else {
                                            fatalError()
                                        }
                                        
                                        var retList = lst
                                        retList.append(.symbol("nil"))
                                        return .list(retList)
                                    }
            ])
        passManager.addPass(transform: t)
    }
    
    func addExplicitDoInLetBodyPass() {
        let t = LanguageTransform(addClauses: [
            "('let ([s ε]+) ε)"
            ],
                                   removeClauses: [
                                    "('let ([s ε]+) ε+)"
            ],
                                   transformations: [
                                    "('let ([s ε]+) ε+)": { input in
                                        // Add explicit do form around let body if it has more than one form
                                        guard case let .list(lst) = input else {
                                            fatalError()
                                        }
                                        
                                        // Don't wrap in a do if there is only one expression in the body
                                        if lst.count == 3 {
                                            return input
                                        }
                                        
                                        let head = lst[0..<2]
                                        let tail = Array(lst.dropFirst(2))
                                        let newTail = LispType.list([.symbol("do")] + tail)
                                        
                                        return .list(Array(head) + [newTail])
                                    }
            ])
        passManager.addPass(transform: t)
    }
    
    func addExplicitDoInFunctionBodyPass() {
        let t = LanguageTransform(addClauses: [
            "('fn ([s*]) ε)"
            ],
                                   removeClauses: [
                                    "('fn ([s*]) ε+)"
            ],
                                   transformations: [
                                    "('fn ([s*]) ε+)": { input in
                                        // Add explicit do form around function body if it has more than one form
                                        guard case let .list(lst) = input else {
                                            fatalError()
                                        }
                                        
                                        // Don't wrap in a do if there is only one expression in the body
                                        if lst.count == 3 {
                                            return input
                                        }
                                        
                                        let head = lst[0..<2]
                                        let tail = Array(lst.dropFirst(2))
                                        let newTail = LispType.list([.symbol("do")] + tail)
                                        
                                        return .list(Array(head) + [newTail])
                                    }
            ])
        passManager.addPass(transform: t)
    }
}
