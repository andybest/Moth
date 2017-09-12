//
//  Micropass.swift
//  MothPackageDescription
//
//  Created by Andy Best on 12/09/2017.
//

import Foundation

class Language<T> {
    var constructs: [LanguageConstruct<T>] {
        didSet {
            for c in constructs {
                c.parentLanguage = self
            }
        }
    }
    
    init() {
        constructs = []
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
    
    let list = LanguageConstruct<LispType>().settingName("list")
        =? {
            switch $0 {
            case .list(_): return true
            default: return false
            }
        }
    
    let anyType = LanguageConstruct<LispType>().settingName("any")
        =? { t in
            return true
    }
    
    let datum = OneOfConstruct<LispType>(symbol, boolean)
    datum.constructs.append(ListConstruct(MultiConstruct(datum)))
    
    let expression = OneOfConstruct<LispType>()
    // Need to give this an explicit name, or we'll end up with a stack overflow error, since it is recursive.
    expression.explicitName = "ε"
    
    let quote = ListConstruct( SymbolConstruct(symbolName: "quote"), datum ).settingName("quote")
    quote.transformChildForms = false
    
    let ifOneArmed = ListConstruct( SymbolConstruct(symbolName: "if"), expression, expression).settingName("ifOneArmed")
    let ifTwoArmed = ListConstruct( SymbolConstruct(symbolName: "if"), expression, expression, expression).settingName("ifTwoArmed")
    let doBlock = ListConstruct( SymbolConstruct(symbolName: "do"), MultiConstruct(expression)).settingName("doBlock")
    
    let fArgs = ListConstruct(MultiConstruct(symbol))
    fArgs.transformChildForms = false
    let function = ListConstruct( SymbolConstruct(symbolName: "fn"), fArgs, MultiConstruct(expression)).settingName("functionDef")
    let apply = ListConstruct(symbol, MultiConstruct(expression)).settingName("applyForm")
    
    let lang = Language<LispType>()
    
    lang.constructs = [
        symbol,
        boolean,
        quote,
        ifOneArmed,
        ifTwoArmed,
        doBlock,
        function,
        apply
    ]
    
    expression.constructs = lang.constructs
    
    let test = LispType.list([.symbol("if"), .boolean(true), .list([.symbol("if"), .boolean(false), .symbol("A")])])
    let test1 = LispType.list([.symbol("fn"),
                               .list([.symbol("x"), .symbol("y")]),
                               .list([.symbol("+"), .symbol("x"), .symbol("y")])
        ])
    
    lang.addTransformerForConstruct("ifOneArmed") { input in
        guard case let .list(lst) = input else {
            fatalError()
        }
        
        var retList = lst
        retList.append(.symbol("nil"))
        return .list(retList)
    }
    
    let lang2 = lang.createChildLanguage()
    
    lang2.addTransformerForConstruct("functionDef") { input in
        guard case let .list(lst) = input else {
            fatalError()
        }
        
        let head = lst[0..<2]
        let tail = Array(lst.dropFirst(2))
        let newTail = LispType.list([.symbol("do")] + tail)
        
        return .list(Array(head) + [newTail])
    }
    
    let passes = [
        lang,
        lang2
    ]
    
    let testInput = """
    (fn (x y)
        (if (and (not (nil? x)) (not (nil? y)))
            (+ x y)))
    """
    
    let testForm = try! Reader.read(testInput)
    
    var output = testForm
    
    print(output)
    
    for pass in passes {
        output = pass.doPass(output)
    }
    
    print(output)
}
