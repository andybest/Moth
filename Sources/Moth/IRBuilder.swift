//
//  IRBuilder.swift
//  Moth
//
//  Created by Andy Best on 27/08/2017.
//

import Foundation
import LLVM

class BuilderEnvironment {
    var functions: [String: LLVM.Function] = [:]
}

class Builder {
    let module: Module
    let builder: IRBuilder
    let mainFunc: LLVM.Function
    let environment: BuilderEnvironment = BuilderEnvironment()
    
    init() {
        module = Module(name: "main")
        builder = IRBuilder(module: module)
        
        let mainFuncType = FunctionType(argTypes: [], returnType: IntType.int64)
        mainFunc = builder.addFunction("main", type: mainFuncType)
        let entry = mainFunc.appendBasicBlock(named: "entry")
        builder.positionAtEnd(of: entry)
        
        let printFunc = builder.addFunction("print", type: FunctionType(argTypes: [], returnType: VoidType()))
        environment.functions["print"] = printFunc
    }
    
    func lookupFunction(_ name: String) -> IRValue? {
        
        return environment.functions[name]
    }
    
    func buildIR(_ mir: MothIR) throws {
        switch mir {
        case .functionCall(let fc):
            try emitFuncCall(fc)
            
        default: break
        }
    }
    
    func emitArgs(_ fc: FunctionCall) throws -> [IRValue] {
        var vals = [IRValue]()
        
        for arg in fc.args {
            switch arg {
            case .functionCall(let fc):
                vals.append(try emitFuncCall(fc))
            case .integer(let i):
                vals.append(IntType.int64.constant(i))
            case .float(let f):
                vals.append(FloatType.double.constant(f))
            default:
                break
            }
        }
        
        return vals
    }
    
    func emitBuiltin(_ fc: FunctionCall) throws -> IRValue? {
        if fc.name == "+" {
            let args = try emitArgs(fc)
            
            var rv = builder.buildAdd(args[0], args[1])
            
            for arg in args.dropFirst(2) {
                rv = builder.buildAdd(rv, arg)
            }
            
            return rv
        } else if fc.name == "-" {
            
        }
        
        return nil
    }
    
    func emitFuncCall(_ fc: FunctionCall) throws -> IRValue {
        if let rv = try emitBuiltin(fc) {
            return rv
        }
        
        guard let function = lookupFunction(fc.name) else {
            throw LispError.general(msg: "Unknown function \(fc.name)")
        }
        
        let rv = try builder.buildCall(function, args: emitArgs(fc))
        return rv
    }
}


