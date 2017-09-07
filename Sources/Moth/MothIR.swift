import LLVM

/*
 (define addxy (fn (x y)
     (+ x y))
 
 .defFunction(name: addxy, argNames: [x y], body: [
     .pushVariable("x")
     .pushVariable("y")
     .add(2)
     .return
 ])
 
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

enum MothIR: CustomStringConvertible {
    case defLabel(String)
    case defFunction(name: String?, argNames: [String], body: [MothIR])
    
    case pushImmediate(MIRValue)
    case pushVariable(name: String)
    
    case setLocal(MIRValue)
    
    // Branches
    case recur(to: String)  // Recur will first evaluate all deferred instructions
    case jump(to: String)
    case jumpNotZero(to: String)
    
    // Math operations
    case add(count: Int)
    case subtract(count: Int)
    
    case retStackTop
    
    case `defer`([MothIR])
    
    var description: String {
        return descriptionString()
    }
    
    func descriptionString(indentLevel: Int = 0) -> String {
        let indent = String(repeating: "\t", count: indentLevel)
        
        switch self {
        case .add(count: let count):
            return indent + "add(\(count))"
        case .defer(let body):
            return indent + "defer {\n\(body.map { $0.descriptionString(indentLevel: indentLevel + 1) }.joined(separator: "\n"))\n}"
        case .defFunction(name: let name, argNames: let argnames, body: let body):
            return indent + "def func(\(argnames.joined(separator: ", "))) {\n\(body.map { $0.descriptionString(indentLevel: indentLevel + 1) }.joined(separator: "\n"))\n}"
        case .defLabel(let name):
            return indent + "\(name):"
        case .retStackTop:
            return indent + "returnStackTop"
        case .pushVariable(name: let name):
            return indent + "pushVariable(\(name))"
        case .pushImmediate(let value):
            return indent + "pushImmediate(\(value))"
        default: return ""
        }
    }
}

struct MIRFuncCall {
    let name: String
    let args: [MothIR]
}

struct MIRFunc {
    
}

class EvaluationEnvironment {
    let builder: IRBuilder
    var valueStack: [IRValue]
    
    var localVariables: [String: IRValue]
    
    init(builder: IRBuilder) {
        self.builder = builder
        self.valueStack = []
        self.localVariables = [:]
    }
    
    func pushValue(_ value: IRValue) {
        valueStack.append(value)
    }
    
    func popValue() -> IRValue?
    {
        return valueStack.popLast()
    }
    
    func setLocal(name: String, value: IRValue) {
        localVariables[name] = value
    }
    
    func getLocal(name: String) -> IRValue? {
        return localVariables[name]
    }
}


func formToMIR(_ form: LispType) -> [MothIR] {
    var ir = [MothIR]()
    
    /*switch form {
    case .list(let lst):
        guard lst.count > 0  else {
            fatalError()
        }
        
        guard case let .symbol(sym) = lst.first! else {
            fatalError()
        }
    }*/
    
    return ir
}

func specialFormToMIR(symbol: String, args: [LispType]) -> [MothIR] {
    /*switch symbol {
    case "define":
        break
    case "fn":
        guard args.count > 1 else {
            fatalError("Not enough forms in function body!")
        }
        
        guard case let .list(fnArgs) = args.first! else {
            fatalError("No function arguments!")
        }
        
        let fnBody = args.dropFirst()
    }*/
    
    return []
}
