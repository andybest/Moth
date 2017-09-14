//
//  Micropass.swift
//  MothPackageDescription
//
//  Created by Andy Best on 12/09/2017.
//

import Foundation

enum ConstructPosition {
    case beginning
    case beforeEnd
    case end
}
/*
class PassManager<T> {
    typealias Transform = (T) -> T
    var languages: [Language<T>] = []
    
    init(baseLanguage: Language<T>) {
        languages.append(baseLanguage)
    }
    
    func addPass(addConstructs: [(name: String, position: ConstructPosition, construct: LanguageConstruct<T>)],
                 removeConstructs: [String],
                 transformations: [String: Transform]) {
        let newLang = languages.last!.createChildLanguage()
        
        for c in addConstructs {
            newLang.addConstruct(name: c.name, position: c.position, construct: c.construct)
        }
        
        for transform in transformations {
            newLang.addTransformerForConstruct(transform.key, transformer: transform.value)
        }
        
        for c in removeConstructs {
            newLang.removeConstruct(c)
        }
        
        languages.append(newLang)
    }
    
    func runPasses(input: T) -> T {
        return languages.reduce(input) {
            $1.doPass($0)
        }
    }
    
}

class Language<T> {
    var expression: ExpressionConstruct<T>
    
    var constructs: [LanguageConstruct<T>] {
        didSet {
            for c in constructs {
                c.parentLanguage = self
            }
        }
    }
    
    var removeConstructs: [String] = []
    
    init() {
        constructs = []
        expression = ExpressionConstruct<T>()
        expression.parentLanguage = self
    }
    
    func matchingConstruct(_ input: T) -> LanguageConstruct<T>? {
        for c in constructs {
            if c.matches(input: input) {
                return c
            }
        }
        
        return nil
    }
    
    func doPass(_ input: T) -> T {
        let c = matchingConstruct(input)
        return c!.transform(input: input)
    }
    
    func createChildLanguage() -> Language<T> {
        let newLang = Language()
        newLang.constructs = constructs.map {
            $0.clone()
            }.filter {
                !removeConstructs.contains($0.name)
        }
        
        return newLang
    }
    
    func addTransformerForConstruct(_ name: String, transformer: @escaping (T) -> T) {
        let filtered = constructs.filter { $0.name == name }
        guard let c = filtered.first else {
            fatalError("Construct \(name) doesn't exist!")
        }
        
        c.transformFunc = transformer
    }
    
    func addConstruct(name: String, position: ConstructPosition, construct: LanguageConstruct<T>) {
        switch position {
        case .beginning:
            constructs.insert(construct.settingName(name), at: 0)
        case .beforeEnd:
            if constructs.count > 1 {
                constructs.insert(construct.settingName(name), at: constructs.endIndex)
            } else {
                addConstruct(name: name, position: .beginning, construct: construct)
            }
        case .end:
            constructs.insert(construct.settingName(name), at: constructs.endIndex)
        }
    }
    
    func removeConstruct(_ name: String) {
        removeConstructs.append(name)
    }
}

class LanguageConstruct<T> {
    var parentLanguage: Language<T>?
    var explicitName: String?
    var matchFunc: ((T) -> Bool)?
    var transformFunc: ((T) -> T)?
    
    var name: String {
        if explicitName != nil {
            return explicitName!
        }
        
        return String(describing: self)
    }
    
    init() {
    }
    
    required init(other: LanguageConstruct<T>) {
        self.explicitName = other.explicitName
        self.matchFunc = other.matchFunc
    }
    
    func transform(input: T) -> T {
        guard let tf = transformFunc else {
            return input
        }
        
        return tf(input)
    }
    
    func matches(input: T) -> Bool {
        guard let mf = matchFunc else {
            fatalError("Missing match func: \(String(describing:self))")
        }
        
        return mf(input)
    }
    
    func settingName(_ n: String) -> Self {
        self.explicitName = n
        return self
    }
    
    func clone() -> Self {
        let newLang = type(of: self).init(other: self)
        return newLang
    }
}

infix operator =?: AdditionPrecedence
infix operator =>: AdditionPrecedence

extension LanguageConstruct {
    static func =? (lc: LanguageConstruct, matchFunc: @escaping (T) -> Bool) -> LanguageConstruct {
        lc.matchFunc = matchFunc
        return lc
    }
    
    static func => (lc: LanguageConstruct, transformFunc: @escaping (T) -> T) -> LanguageConstruct {
        lc.transformFunc = transformFunc
        return lc
    }
}

class ExpressionConstruct<T>: LanguageConstruct<T> {
    var e: OneOfConstruct<T> {
        let c = OneOfConstruct<T>()
        c.constructs = parentLanguage!.constructs
        c.explicitName = "ε"
        
        return c
    }
    
    override func matches(input: T) -> Bool {
        return e.matches(input: input)
    }
    
    override func transform(input: T) -> T {
        return e.transform(input: input)
    }
}

class MultiConstruct<T>: LanguageConstruct<T> {
    let matchingConstruct: LanguageConstruct<T>
    
    override var name: String {
        if self.explicitName != nil {
            return explicitName!
        }
        
        return "[\(matchingConstruct.name)...]"
    }
    
    
    init(_ matchingConstruct: LanguageConstruct<T>) {
        self.matchingConstruct = matchingConstruct
        super.init()
    }
    
    required init(other: LanguageConstruct<T>) {
        if other is MultiConstruct<T> {
            self.matchingConstruct = (other as! MultiConstruct<T>).matchingConstruct
            super.init(other: other)
        }
        
        fatalError()
    }
    
    override func matches(input: T) -> Bool {
        return matchingConstruct.matches(input: input)
    }
}

class SymbolConstruct: LanguageConstruct<LispType> {
    var symbolName: String
    
    override var name: String {
        if self.explicitName != nil {
            return explicitName!
        }
        
        return symbolName
    }
    
    init(symbolName: String) {
        self.symbolName = symbolName
        super.init()
    }
    
    required init(other: LanguageConstruct<LispType>) {
        if other is SymbolConstruct {
            self.symbolName = (other as! SymbolConstruct).symbolName
            super.init(other: other)
        }
        
        fatalError()
    }
    
    override func matches(input: LispType) -> Bool {
        switch input {
        case .symbol(let sym):
            return sym == symbolName
        default: return false
        }
    }
}

class OneOfConstruct<T>: LanguageConstruct<T> {
    var constructs: [LanguageConstruct<T>]
    
    override var name: String {
        if self.explicitName != nil {
            return explicitName!
        }
        
        let n = constructs.map { $0.name }.joined(separator: " | ")
        return "[\(n)]"
    }
    
    init(_ constructs: LanguageConstruct<T>...) {
        self.constructs = constructs
        super.init()
    }
    
    required init(other: LanguageConstruct<T>) {
        if other is OneOfConstruct<T> {
            self.constructs = (other as! OneOfConstruct<T>).constructs
            super.init(other: other)
        }
        
        fatalError()
    }
    
    override func matches(input: T) -> Bool {
        for c in constructs {
            if c.matches(input: input) {
                return true
            }
        }
        
        return false
    }
}

class ListConstruct: LanguageConstruct<LispType> {
    var body: [LanguageConstruct<LispType>]
    var transformChildForms: Bool = true
    
    override var name: String {
        if self.explicitName != nil {
            return explicitName!
        }
        
        
        let n = body.map { $0.name }.joined(separator: " ")
        return "(\(n))"
    }
    
    init(_ body: LanguageConstruct<LispType>...) {
        self.body = body
        super.init()
    }
    
    required init(other: LanguageConstruct<LispType>) {
        self.body = (other as! ListConstruct).body
        self.transformChildForms = (other as! ListConstruct).transformChildForms
        super.init(other: other)
    }
    
    override func matches(input: LispType) -> Bool {
        switch input {
        case .list(let lst):
            var remaining = lst
            
            for c in body {
                if c is MultiConstruct<LispType> {
                    if remaining.first == nil {
                        return false
                    }
                    
                    if c.matches(input: remaining.first!) {
                        while remaining.first != nil && c.matches(input: remaining.first!) {
                            remaining = Array(remaining.dropFirst())
                        }
                    }
                } else {
                    if remaining.first == nil {
                        return false
                    }
                    
                    if !c.matches(input: remaining.first!) {
                        return false
                    }
                    
                    remaining = Array(remaining.dropFirst())
                }
            }
            
            if remaining.count > 0 {
                return false
            }
            
            return true
            
            
        default:
            return false
        }
    }
    
    override func transform(input: LispType) -> LispType {
        if !transformChildForms {
            return input
        }
        
        var retList = [LispType]()
        
        switch input {
        case .list(let lst):
            let lang = self.parentLanguage!
            
            for item in lst {
                let c = lang.matchingConstruct(item)!
                retList.append(c.transform(input: item))
            }
            
            if let tf = transformFunc {
                return tf(.list(retList))
            }
            
            return .list(retList)
            
        default:
            fatalError("Cannot transform non-matching input!")
        }
    }
}

func make() {
    let symbol = LanguageConstruct<LispType>().settingName("symbol")
        =? {
            switch $0 {
            case .symbol(_): return true
            default: return false
            }
    }
    
    let boolean = LanguageConstruct<LispType>().settingName("boolean")
        =? {
            switch $0 {
            case .boolean(_): return true
            default: return false
            }
    }
    
    let lang = Language<LispType>()
    
    let datum = OneOfConstruct<LispType>(symbol, boolean)
    datum.constructs.append(ListConstruct(MultiConstruct(datum)))
    
    let quote = ListConstruct( SymbolConstruct(symbolName: "quote"), datum ).settingName("quote")
    quote.transformChildForms = false
    
    let ifOneArmed = ListConstruct( SymbolConstruct(symbolName: "if"), lang.expression, lang.expression).settingName("ifOneArmed")
    let ifTwoArmed = ListConstruct( SymbolConstruct(symbolName: "if"), lang.expression, lang.expression, lang.expression).settingName("ifTwoArmed")
    let doBlock = ListConstruct( SymbolConstruct(symbolName: "do"), MultiConstruct(lang.expression)).settingName("doBlock")
    
    let fArgs = ListConstruct(MultiConstruct(symbol))
    fArgs.transformChildForms = false
    let function = ListConstruct( SymbolConstruct(symbolName: "fn"), fArgs, MultiConstruct(lang.expression)).settingName("functionDef")
    let apply = ListConstruct(symbol, MultiConstruct(lang.expression)).settingName("applyForm")
    
    let letForm = ListConstruct( SymbolConstruct(symbolName: "let"),
                                 ListConstruct(MultiConstruct(lang.expression)), MultiConstruct(lang.expression)).settingName("letForm")
    
    
    lang.constructs = [
        symbol,
        boolean,
        quote,
        ifOneArmed,
        ifTwoArmed,
        doBlock,
        function,
        letForm,
        apply
    ]
    
    let passManager = PassManager(baseLanguage: lang)
    
    // Remove one armed if, repace with a 2 armed, with the second returning nil
    passManager.addPass(addConstructs: [],
                        removeConstructs: [
                            "ifOneArmed"
        ],
                        transformations: [
                            "ifOneArmed": { input in
                                guard case let .list(lst) = input else {
                                    fatalError()
                                }
                                
                                var retList = lst
                                retList.append(.symbol("nil"))
                                return .list(retList)
                            }
        ])
    
    // Add an explicit "do" form around function bodies
    passManager.addPass(addConstructs: [
        (name: "functionDef", position: .beforeEnd, construct: ListConstruct( SymbolConstruct(symbolName: "fn"), fArgs, doBlock))
        ],
                        removeConstructs: [],
                        transformations: [
                            
                            "functionDef": { input in
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
    
    // Add an explicit "do" form around let bodies
    passManager.addPass(addConstructs: [
        (name: "letForm", position: .beforeEnd, construct: ListConstruct( SymbolConstruct(symbolName: "let"),
                                                                          ListConstruct(MultiConstruct(lang.expression)), doBlock))
        ],
                        removeConstructs: [
                            "letForm"
        ],
                        transformations: [
                            "letForm": { input in
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
    
    // Remove Not
    passManager.addPass(addConstructs: [
        (name: "notForm", position: .beginning, construct: ListConstruct( SymbolConstruct(symbolName: "not"), lang.expression)),
        (name: "ifNotForm", position: .beginning, construct: ListConstruct(SymbolConstruct(symbolName: "if"), ListConstruct(SymbolConstruct(symbolName: "not"), lang.expression), lang.expression, lang.expression))
        ],
                        removeConstructs: [
                            "notForm",
                            "ifNotForm"
        ],
                        transformations: [
                            "notForm": { input in
                                /* Replace:
                                     (not x)
                                   with:
                                     (if x false true)
                                 */
                                
                                guard case let .list(lst) = input else {
                                    fatalError()
                                }
                                
                                let v = lst[1]
                                
                                return .list([.symbol("if"), v, .symbol("false"), .symbol("true")])
                            },
                            "ifNotForm": { input in
                                /* Replace:
                                     (if (not x) ε1 ε2)
                                 with:
                                     (if x ε2 ε1)
                                 */
                                
                                guard case let .list(ifList) = input else {
                                    fatalError()
                                }
                                
                                guard case let .list(notList) = ifList[1] else {
                                    fatalError()
                                }
                                
                                return .list([.symbol("if"), notList[1], ifList[3], ifList[2]])
                            }
        ])
    
    let testInput = """
    (fn (x y)
        (if (and (not (nil? x)) (not (nil? y)))
            (let (result (+ x y))
                (if (not x)
                    result))))
    """
    
    let testForm = try! Reader.read(testInput)
    let output = passManager.runPasses(input: testForm)
    
    print(testForm)
    print(output)
}*/
