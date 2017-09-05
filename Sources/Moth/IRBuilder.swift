//
//  IRBuilder.swift
//  Moth
//
//  Created by Andy Best on 27/08/2017.
//

import Foundation
import LLVM
import cllvm

class BuilderEnvironment {
    var functions: [String: LLVM.Function] = [:]
}

struct MIRGlobalFuncs {
    let gcInit: Function
    let gcMalloc: Function
}

class Builder {
    let module: Module
    let builder: IRBuilder
    let mainFunc: LLVM.Function
    let environment: BuilderEnvironment = BuilderEnvironment()
    
    var globalFuncs: MIRGlobalFuncs!
    var consType: StructType!
    var floatType: FloatType!
    var intType: IntType!
    var consPointerType: PointerType!
    
    var boxedUnionType: IntType!
    var boxType: StructType!
    
    init() {
        module = Module(name: "main")
        builder = IRBuilder(module: module)
        
        let mainFuncType = FunctionType(argTypes: [], returnType: IntType.int64)
        mainFunc = builder.addFunction("main", type: mainFuncType)
        
        let entry = mainFunc.appendBasicBlock(named: "entry")
        builder.positionAtEnd(of: entry)
        
        let printFunc = builder.addFunction("print", type: FunctionType(argTypes: [], returnType: VoidType()))
        environment.functions["print"] = printFunc
        
        initTypes()
        initGlobalFuncs()
        
        let c = buildGCMalloc(consType)

    }
    
    func initTypes() {
        consType = builder.createStruct(name: "MothCons")
        consType.setBody([IntType.int64, PointerType(pointee: consType)])
        
        intType = IntType.int64
        floatType = FloatType.double
        consPointerType = PointerType(pointee: consType)
        
        /* Create types equivalent to the following struct:
             typedef struct
             {
                 uint8_t type;
 
                 union {
                     uint64_t intValue;
                     double floatValue;
                     MothCons* listValue;
                 } value;
             } MothBoxedValue;
         */
        
        let types: [IRType] = [intType, floatType, consPointerType]
        
        let greatestBitWidth = types.reduce(0) {
            let size = module.dataLayout.sizeOfTypeInBits($1)
            return $0 > size ? $0 : size
        }
        
        // Create an int type that is big enough to hold the largest boxed value
        boxedUnionType = IntType(width: greatestBitWidth)
        
        boxType = builder.createStruct(name: "MothBoxedValue")
        boxType.setBody([IntType.int8, boxedUnionType])
    }
    
    func initGlobalFuncs() {
        let targetPtrSize = module.dataLayout.pointerSize()
        let targetIntType = IntType(width: targetPtrSize * 8)
        
        let gcInit = builder.addFunction("GC_init", type: FunctionType(argTypes: [], returnType: VoidType()))
        let gcMalloc = builder.addFunction("GC_malloc", type: FunctionType(argTypes: [targetIntType], returnType: PointerType.toVoid))
        
        self.globalFuncs = MIRGlobalFuncs(gcInit: gcInit, gcMalloc: gcMalloc)
    }
    
    func buildGCMalloc(_ type: IRType) -> IRValue {
        let targetPtrSize = module.dataLayout.pointerSize()
        let targetIntType = IntType(width: targetPtrSize * 8)
        
        let typeSize = module.dataLayout.storeSize(of: type)
        return builder.buildCall(globalFuncs.gcMalloc, args: [targetIntType.constant(typeSize)])
    }
    
    func buildBoxedInt(_ val: Int) {
        let boxedVal = builder.buildMalloc(boxType)
        let boxPtr = builder.buildStructGEP(boxedVal, index: 0)
    }
    
    func lookupFunction(_ name: String) -> IRValue? {
        
        return environment.functions[name]
    }
    
    func buildIR(_ mir: MothIR) throws {
        /*
             typedef struct
             {
                 uint8_t type;
 
             union {
                 uint64_t intValue;
                 double floatValue;
                 MothCons* listValue;
             } value;
 
             } MothBoxedValue;
         */
        

    }
}


