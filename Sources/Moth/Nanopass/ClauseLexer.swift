/*
 
 MIT License
 
 Copyright (c) 2017 Andy Best
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 */

import Foundation

public enum ClauseLexerError: Error {
    case lexer(msg: String)
}

public enum ClauseTokenType {
    case lParen(TokenPosition)
    case rParen(TokenPosition)
    case lSquareBracket(TokenPosition)
    case rSquareBracket(TokenPosition)
    case terminalSymbol(TokenPosition, String)
    case literalSymbol(TokenPosition, String)
    
    case plus(TokenPosition)
    case asterisk(TokenPosition)
}

public func ==(a: ClauseTokenType, b: ClauseTokenType) -> Bool {
    switch (a, b) {
    case (.lParen, .lParen): return true
    case (.rParen, .rParen): return true
    case (.lSquareBracket, .lSquareBracket): return true
    case (.rSquareBracket, .rSquareBracket): return true
    case (.terminalSymbol(_, let a), .terminalSymbol(_, let b)) where a == b: return true
    case (.literalSymbol(_, let a), .literalSymbol(_, let b)) where a == b: return true
    case (.plus, .plus): return true
    case (.asterisk, .asterisk): return true
    default: return false
    }
}

protocol ClauseTokenMatcher {
    static func isMatch(_ stream:StringStream) -> Bool
    static func getToken(_ stream:StringStream) throws -> ClauseTokenType?
}

class LParenClauseTokenMatcher: ClauseTokenMatcher {
    static func isMatch(_ stream: StringStream) -> Bool {
        return stream.currentCharacter == "("
    }
    
    static func getToken(_ stream: StringStream) -> ClauseTokenType? {
        if isMatch(stream) {
            stream.advanceCharacter()
            return ClauseTokenType.lParen(TokenPosition(line: stream.currentLine, column: stream.currentColumn, source: stream.str))
        }
        return nil
    }
}

class RParenClauseTokenMatcher: ClauseTokenMatcher {
    static func isMatch(_ stream: StringStream) -> Bool {
        return stream.currentCharacter == ")"
    }
    
    static func getToken(_ stream: StringStream) -> ClauseTokenType? {
        if isMatch(stream) {
            stream.advanceCharacter()
            return ClauseTokenType.rParen(TokenPosition(line: stream.currentLine, column: stream.currentColumn, source: stream.str))
        }
        return nil
    }
}

class LSquareBracketClauseTokenMatcher: ClauseTokenMatcher {
    static func isMatch(_ stream: StringStream) -> Bool {
        return stream.currentCharacter == "["
    }
    
    static func getToken(_ stream: StringStream) -> ClauseTokenType? {
        if isMatch(stream) {
            stream.advanceCharacter()
            return ClauseTokenType.lSquareBracket(TokenPosition(line: stream.currentLine, column: stream.currentColumn, source: stream.str))
        }
        return nil
    }
}

class RSquareBracketClauseTokenMatcher: ClauseTokenMatcher {
    static func isMatch(_ stream: StringStream) -> Bool {
        return stream.currentCharacter == "]"
    }
    
    static func getToken(_ stream: StringStream) -> ClauseTokenType? {
        if isMatch(stream) {
            stream.advanceCharacter()
            return ClauseTokenType.rSquareBracket(TokenPosition(line: stream.currentLine, column: stream.currentColumn, source: stream.str))
        }
        return nil
    }
}

class PlusClauseTokenMatcher: ClauseTokenMatcher {
    static func isMatch(_ stream: StringStream) -> Bool {
        return stream.currentCharacter == "+"
    }
    
    static func getToken(_ stream: StringStream) -> ClauseTokenType? {
        if isMatch(stream) {
            stream.advanceCharacter()
            return ClauseTokenType.plus(TokenPosition(line: stream.currentLine, column: stream.currentColumn, source: stream.str))
        }
        return nil
    }
}

class AsteriskClauseTokenMatcher: ClauseTokenMatcher {
    static func isMatch(_ stream: StringStream) -> Bool {
        return stream.currentCharacter == "*"
    }
    
    static func getToken(_ stream: StringStream) -> ClauseTokenType? {
        if isMatch(stream) {
            stream.advanceCharacter()
            return ClauseTokenType.asterisk(TokenPosition(line: stream.currentLine, column: stream.currentColumn, source: stream.str))
        }
        return nil
    }
}

class TerminalSymbolMatcher: ClauseTokenMatcher {
    static var matcherCharacterSet: NSMutableCharacterSet?
    static var matcherStartCharacterSet: NSMutableCharacterSet?
    
    static func isMatch(_ stream: StringStream) -> Bool {
        return characterIsInSet(stream.currentCharacter!, set: startCharacterSet())
    }
    
    static func getToken(_ stream: StringStream) -> ClauseTokenType? {
        if isMatch(stream) {
            var tok = ""
            
            while characterIsInSet(stream.currentCharacter!, set: characterSet()) {
                tok += String(stream.currentCharacter!)
                stream.advanceCharacter()
                if stream.currentCharacter == nil {
                    break
                }
            }
            
            return ClauseTokenType.terminalSymbol(TokenPosition(line: stream.currentLine, column: stream.currentColumn, source: stream.str), tok)
        }
        return nil
    }
    
    static func characterSet() -> CharacterSet {
        if matcherCharacterSet == nil {
            matcherCharacterSet = NSMutableCharacterSet.letter()
            matcherCharacterSet!.formUnion(with: CharacterSet.decimalDigits)
            matcherCharacterSet!.formUnion(with: CharacterSet.punctuationCharacters)
            matcherCharacterSet!.formUnion(with: NSMutableCharacterSet.symbol() as CharacterSet)
            matcherCharacterSet!.removeCharacters(in: "()[]*+'")
        }
        return matcherCharacterSet! as CharacterSet
    }
    
    static func startCharacterSet() -> CharacterSet {
        if matcherStartCharacterSet == nil {
            matcherStartCharacterSet = NSMutableCharacterSet.letter()
            matcherStartCharacterSet!.formUnion(with: CharacterSet.punctuationCharacters)
            matcherStartCharacterSet!.formUnion(with: NSMutableCharacterSet.symbol() as CharacterSet)
            matcherStartCharacterSet!.removeCharacters(in: "()[]*+'")
        }
        return matcherStartCharacterSet! as CharacterSet
    }
}

class LiteralSymbolMatcher: ClauseTokenMatcher {
    static var matcherCharacterSet: NSMutableCharacterSet?
    static var matcherStartCharacterSet: NSMutableCharacterSet?
    
    static func isMatch(_ stream: StringStream) -> Bool {
        return characterIsInSet(stream.currentCharacter!, set: startCharacterSet())
    }
    
    static func getToken(_ stream: StringStream) -> ClauseTokenType? {
        if isMatch(stream) {
            var tok = ""
            
            stream.advanceCharacter()
            
            while characterIsInSet(stream.currentCharacter!, set: characterSet()) {
                tok += String(stream.currentCharacter!)
                stream.advanceCharacter()
                if stream.currentCharacter == nil {
                    break
                }
            }
            
            return ClauseTokenType.literalSymbol(TokenPosition(line: stream.currentLine, column: stream.currentColumn, source: stream.str), tok)
        }
        return nil
    }
    
    static func characterSet() -> CharacterSet {
        if matcherCharacterSet == nil {
            matcherCharacterSet = NSMutableCharacterSet.letter()
            matcherCharacterSet!.formUnion(with: CharacterSet.decimalDigits)
            matcherCharacterSet!.formUnion(with: CharacterSet.punctuationCharacters)
            matcherCharacterSet!.formUnion(with: NSMutableCharacterSet.symbol() as CharacterSet)
            matcherCharacterSet!.removeCharacters(in: "()[]*+'")
        }
        return matcherCharacterSet! as CharacterSet
    }
    
    static func startCharacterSet() -> CharacterSet {
        if matcherStartCharacterSet == nil {
            matcherStartCharacterSet = NSMutableCharacterSet(charactersIn: "'")
        }
        return matcherStartCharacterSet! as CharacterSet
    }
}



// Token matchers in order
let clauseTokenClasses: [ClauseTokenMatcher.Type] = [
    LParenClauseTokenMatcher.self,
    RParenClauseTokenMatcher.self,
    LSquareBracketClauseTokenMatcher.self,
    RSquareBracketClauseTokenMatcher.self,
    PlusClauseTokenMatcher.self,
    AsteriskClauseTokenMatcher.self,
    LiteralSymbolMatcher.self,
    TerminalSymbolMatcher.self
]

class ClauseTokenizer {
    let stream: StringStream
    var currentClauseTokenMatcher: ClauseTokenMatcher.Type? = nil
    var currentTokenString: String
    
    init(source: String) {
        self.stream = StringStream(source: source)
        self.currentTokenString = ""
    }
    
    func tokenizeInput() throws -> [ClauseTokenType] {
        var tokens = [ClauseTokenType]()
        
        while let t = try getNextToken() {
            tokens.append(t)
        }
        
        return tokens
    }
    
    func getNextToken() throws -> ClauseTokenType? {
        if stream.position >= stream.str.count {
            return nil
        }
        
        for matcher in clauseTokenClasses {
            if matcher.isMatch(stream) {
                return try matcher.getToken(stream)
            }
        }
        
        let count = stream.eatWhitespace()
        
        if stream.position >= stream.str.count {
            return nil
        }
        
        if stream.currentCharacter == ";" {
            while stream.currentCharacter != "\n" {
                if stream.position >= stream.str.count {
                    return nil
                }
                stream.advanceCharacter()
            }
            stream.advanceCharacter()
            
            if stream.position >= stream.str.count {
                return nil
            }
        } else {
            if count == 0 {
                let pos = TokenPosition(line: stream.currentLine, column: stream.currentColumn + 1, source: stream.str)
                let msg = """
                \(pos.line):\(pos.column): Unrecognized character '\(stream.currentCharacter ?? " ".first!)':
                \t\(pos.sourceLine)
                \t\(pos.tokenMarker)
                """
                throw ClauseLexerError.lexer(msg: msg)
            }
        }
        
        return try getNextToken()
    }
}

