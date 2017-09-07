import XCTest
@testable import Moth

class MIRGenTests: XCTestCase {
    
    func testSimpleFuncDef() {
        /*
         (define addxy (fn (x y)
             (+ x y))
         */
        
        let testForm: LispType = LispType.list([
            LispType.symbol("define"), LispType.symbol("addxy"), LispType.list([
                LispType.symbol("fn"), LispType.list([LispType.symbol("x"), LispType.symbol("y")]),
                    LispType.list([LispType.symbol("+"), LispType.symbol("x"), LispType.symbol("y")])
                ])
            ])
        
        let expectedMIR: [MothIR] = [
            MothIR.defFunction(name: "addxy", argNames: ["x", "y"], body: [
                .pushVariable(name: "x"),
                .pushVariable(name: "y"),
                .add(count: 2),
                .retStackTop
                ])
        ]
        
        let generatedIR = formToMIR(testForm)
        
        print(expectedMIR.description)
        
        XCTAssertEqual(generatedIR.description, expectedMIR.description)
    }
}
