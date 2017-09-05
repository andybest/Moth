import LLVM

/*
 (+ 1 2 (- 4 1))
 
 [
     .functionCall(MIRFuncCall(name: "+", args: [
         .value(.integer(1)),
         .value(integer(2)),
         .functionCall(MIRFuncCall(name: "-", args: [
             .value(.integer(4)), .value(.integer(1))
         ])
     ]
 ]
 
 imv1 = call "-" [ 4, 1 ]
 imv2 = call "+" [ 1, 2, imv1 ]
*/


enum MIRBoxedValueType: Int8 {
    case `nil` = 0
    case int
    case float
    case list
}

enum MIRValue {
    case integer(Int)
    case float(Double)
    case `nil`
}

enum MothIR {
    case defineGlobal(name: String, value: MIRValue)
    case functionCall(MIRFuncCall)
    case defFunction(MIRFunc)
}

struct MIRFuncCall {
    let name: String
    let args: [MothIR]
}

struct MIRFunc {
    
}
