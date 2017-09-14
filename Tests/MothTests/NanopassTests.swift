//
//  NanopassTests.swift
//  MothTests
//
//  Created by Andy Best on 14/09/2017.
//

import XCTest
@testable import Moth

class NanopassTests: XCTestCase {
    
    func testListParsing() {
        let src = "(do (add x y))"
        let input: LispType = try! Reader.read(src)
        
        let clauseSrc = "('do ('add 'x 'y))"
        let pm = PassManager()
        let clause = try! ClauseReader.read(clauseSrc, passManager: pm)
        
        XCTAssertTrue(clause.matches(input))
    }
    
    func testGroupParsing() {
        let src = "(let (x foo y bar) (add x y))"
        let input: LispType = try! Reader.read(src)
        
        let clauseSrc = "('let ([s s]+) (s+))"
        let mgr = PassManager()
       
        let lang = Language(terminalClauses: [
            "s": VariableTerminalClause(passManager: mgr)
            ],
                            clauses: [
                                "('let ([s s]+) (s+))"
            ],
                                    passManager: mgr)
        
        mgr.addLanguage(lang)
        XCTAssertTrue(lang.formMatches(input))
        
        
        // Should not match the following form
        let src2 = "(let (x) (add x))"
        let input2: LispType = try! Reader.read(src2)
        
        XCTAssertFalse(lang.formMatches(input2))
    }
}
