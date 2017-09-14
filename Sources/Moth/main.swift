import LLVM

let module = Module(name: "main")

let testInput = """
(fn (x y)
(if (and (not (nil? x)) (not (nil? y)))
(let (result (+ x y))
(if (not x)
result))))
"""

//let testInput = "(fn (x) x)"

let form = try Reader.read(testInput)

let passManager = PassManager()

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

let t1 = LanguageTransform(addClauses: [],
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

/*let t1 = LanguageTransform(addClauses: [],
                           removeClauses: [
    ],
                           transformations: [
                            "('fn ([s*]) ε+)": { input in
                                return .string("Yay!")
                            }
    ])*/

passManager.addPass(transform: t1)

print(String(describing: form))

let transformed = passManager.runPasses(form)

print(String(describing: transformed))
