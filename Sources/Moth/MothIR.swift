import LLVM

enum MothIR {
    case functionCall(FunctionCall)
    case integer(Int)
    case float(Double)
    case `nil`
}

struct FunctionCall {
    let name: String
    let args: [MothIR]
}

struct Function {
    let type: IRType
}

func formToMothIR(_ form: LispType) -> MothIR {
    switch form {
    case .list(let l):
        return listToMothIR(l)
    case .number(let num):
        switch num {
        case .float(let f):
            return .float(f)
        case .integer(let i):
            return .integer(i)
        }
        
    default: return .nil
    }
}

func listToMothIR(_ list: [LispType]) -> MothIR {
    if case let .symbol(sym) = list.first! {
        // Special form: function call
        let funcName = sym
        let args = list.dropFirst().map { formToMothIR($0) }
        let call = FunctionCall(name: funcName, args: args)
        return .functionCall(call)
    }
    
    return .nil
}
