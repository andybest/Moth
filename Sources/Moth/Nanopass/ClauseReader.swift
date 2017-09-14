//
//  ClauseReader.swift
//  MothPackageDescription
//
//  Created by Andy Best on 14/09/2017.
//

import Foundation

class ClauseReader {
    let tokens: [ClauseTokenType]
    var pos = 0
    weak var passManager: PassManager!
    
    public init(tokens: [ClauseTokenType], passManager: PassManager) {
        self.tokens = tokens
        self.passManager = passManager
    }
    
    func updateCaptureType(_ clause: LanguageClause) {
        
        // If the next token is an asterisk or plus, add the modifier to the clause
        if pos + 1 >= tokens.count {
            return
        }
        
        let tok = tokens[pos + 1]
        
        switch tok {
        case .asterisk(_):
            clause.captureType = .zeroOrMore
            advanceToken()
        case .plus(_):
            clause.captureType = .oneOrMore
            advanceToken()
            
        default: break
        }
    }
    
    func advanceToken() {
        pos += 1
    }
    
    func read_token(_ token: ClauseTokenType) throws -> LanguageClause {
        print("Reading token \(token)")
        switch token {
        case .lParen:
            return try read_list()
        case .lSquareBracket:
            let group = try read_group()
            updateCaptureType(group)
            return group
            
        case .literalSymbol(_, let symbolName):
            let sym = LiteralSymbolClause(symbolName: symbolName, passManager: passManager)
            updateCaptureType(sym)
            return sym
            
        case .terminalSymbol(_, let symbolName):
            let sym = TerminalSymbolClause(symbolName: symbolName, passManager: passManager)
            updateCaptureType(sym)
            return sym
            
        case .rParen(let tokenPos):
            throw LispError.lexer(msg: """
                \(tokenPos.line):\(tokenPos.column): Unexpected ')'
                \t\(tokenPos.sourceLine)
                \t\(tokenPos.tokenMarker)
                """)
            
        case .rSquareBracket(let tokenPos):
            throw LispError.lexer(msg: """
                \(tokenPos.line):\(tokenPos.column): Unexpected ']'
                \t\(tokenPos.sourceLine)
                \t\(tokenPos.tokenMarker)
                """)
            
        case .plus(let tokenPos):
            throw LispError.lexer(msg: """
                \(tokenPos.line):\(tokenPos.column): Unexpected '+'
                \t\(tokenPos.sourceLine)
                \t\(tokenPos.tokenMarker)
                """)
            
        case .asterisk(let tokenPos):
            throw LispError.lexer(msg: """
                \(tokenPos.line):\(tokenPos.column): Unexpected '*'
                \t\(tokenPos.sourceLine)
                \t\(tokenPos.tokenMarker)
                """)
        }
    }
    
    func read_list() throws -> ListClause {
        var body: [LanguageClause] = []
        var endOfList        = false
        
        advanceToken()
        
        var t: ClauseTokenType? = tokens[pos]
        
        while t != nil {
            switch t! {
            case .rParen:
                endOfList = true
            default:
                body.append(try read_token(t!))
            }
            
            if endOfList {
                break
            }
            
            advanceToken()
            t = tokens[pos]
        }
        
        if !endOfList {
            throw LispError.readerNotEOF
        }
        
        return ListClause(body: body, passManager: passManager)
    }
    
    func read_group() throws -> GroupClause {
        var body: [LanguageClause] = []
        var endOfList        = false
        
        advanceToken()
        var t: ClauseTokenType? = tokens[pos]
        
        while t != nil {
            switch t! {
            case .rSquareBracket:
                endOfList = true
            default:
                body.append(try read_token(t!))
            }
            
            if endOfList {
                break
            }
            
            pos += 1
            t = tokens[pos]
        }
        
        if !endOfList {
            throw LispError.readerNotEOF
        }
        
        return GroupClause(body: body, passManager: passManager)
    }
    
    public static func read(_ input: String, passManager: PassManager) throws -> LanguageClause {
        let tokenizer = ClauseTokenizer(source: input)
        let tokens    = try tokenizer.tokenizeInput()
        
        let reader = ClauseReader(tokens: tokens, passManager: passManager)
        return try reader.read_token(tokens[reader.pos])
    }
}
